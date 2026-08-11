---
type: Defect
title: page is accepted by the API and silently ignored
description: The legacy page/size path is not merely deprecated — the API validates page, then always returns the first page, so a loop on hasNext never terminates.
status: resolved
tags: [pagination, issue-20]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** `page`/`size` are converted to `limit`/`offset` rather than sent, so existing callers are fixed instead of broken; non-positive or non-integer values raise `Conexa::RequestError`. Covered by `spec/conexa/legacy_pagination_spec.rb`.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

`GET /contracts` validates `page` (`page=0` → `400 "Page is too small (minimum is
1)"`) and then **ignores it**, always answering with `pagination.offset: 0` and
`hasNext: true`:

```
limit=5&page=1    -> [139, 152, 155, 281, 282]   offset 0
limit=5&page=2    -> [139, 152, 155, 281, 282]   offset 0   <- identical
limit=5&offset=5  -> [284, 286, 289, 291, 292]   offset 5   <- advances
```

This is an upstream behaviour, not a gem bug — but the gem exposes the parameter,
so it inherits the trap. A loop over `page` driven by `hasNext` never terminates
and re-yields the same batch, which looks exactly like real data. It produced a
confident and completely wrong conclusion before anyone noticed the numbers were
suspiciously round.

# The gem only warns

`Model.extract_page_size_or_params` deprecates `page`/`size` in favour of
`limit`/`offset` and strips `:page` when `limit` is present. But when the caller
passes only `page`/`size`, it emits a deprecation warning and **sends them
anyway** — verified 2026-08-11: `Conexa::Contract.all(page: 2, size: 5)` puts
`page=2` on the wire.

The warning frames this as a future removal ("será removido em 01 de agosto de
2026"). That understates it: the legacy path is already **broken against the live
API**, silently, today. A warning is the wrong severity for a code path that
returns plausible wrong answers.

# Suggested fix

Raise `Conexa::RequestError` on `page`/`size` instead of warning, or translate
them to `offset = (page - 1) * size` so the call at least advances. Raising is
safer: a caller relying on `page` is already getting wrong results, and failing
loudly is strictly better than the current silence.

See [Pagination and the Result object](../architecture/pagination.md) for the
supported path, and
[the pagination migration decision](../decisions/pagination-migration.md) for how
the two models came to coexist.

# Citations

[1] [Issue #20, item 6](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20) — sequences observed against a production tenant, 2026-08-07.
[2] `lib/conexa/model.rb` (`extract_page_size_or_params`) — gem v0.1.1.
