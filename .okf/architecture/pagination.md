---
type: Component
title: Pagination and the Result object
description: Two pagination models coexist in the gem — limit/offset (works) and page/size (deprecated, and broken against the live API).
tags: [pagination, api-contract]
timestamp: 2026-08-11T18:40:00Z
---

# Overview

Any listing call (`all`, `where`, `find_by`) returns a `Conexa::Result`, not an
Array. `Result` delegates unknown methods to its `data` array, so `each`/`map`
mostly behave as if it *were* one — but `empty?` is overridden to consult `data`
rather than `@attributes`, because a response with zero rows still carries a
`pagination` object.

## The two models

`Model.extract_page_size_or_params` decides which one applies:

| Caller passes | Result | Status |
|---------------|--------|--------|
| `limit:` (and optional `offset:`) | validated, `page`/`size` stripped | current |
| `page:` / `size:` / a positional page | converted to `limit`/`offset`, with a deprecation warning | removed in 0.3.0 |
| nothing | defaults to `limit: 100, offset: 0` | current |

The default changed to `limit`/`offset` in v0.1.0 — see
[the pagination migration decision](../decisions/pagination-migration.md).

Before 0.2.0 the legacy branch merely warned and sent `page` anyway, which was
worse than it sounds: [the API accepts `page` and ignores
it](../defects/page-param-silently-ignored.md), so the call returned the first
page forever. It now converts to `offset = (page - 1) * size` and raises
`Conexa::RequestError` on a non-positive or non-integer value, so a legacy caller
is quietly fixed rather than loudly broken.

## Walking pages

`Result#next_page` is the supported way forward. It reuses the `query_context`
that `Request#call` attached to the result (the originating class plus the
params), deep-copies the params, advances `offset` by `limit`, and strips any
legacy keys:

```ruby
page = Conexa::Charge.all(limit: 50)
while page.has_next?
  page.data.each { |c| … }
  page = page.next_page
end
```

`next_page` raises `StopIteration` when `pagination.has_next` is false, so it is
safe inside a `loop do … end`. It raises a bare `RuntimeError` if the result did
not come from a `find_by` — e.g. a `Result` you built yourself in a test.

# Citations

[1] `lib/conexa/model.rb` (`extract_page_size_or_params`), `lib/conexa/resources/result.rb` — gem v0.1.1.
[2] `CHANGELOG.md`, v0.1.0.
