---
type: Runbook
title: Validating against the live API
description: How to check a claim about the API without a test tenant — read-only probing, what the collection can and cannot settle, and the endpoints that are never touched.
tags: [api-contract, testing, auth]
timestamp: 2026-08-13T19:00:00Z
---

# Overview

There is no test tenant. Every claim about API behaviour is therefore either
verified against production, read-only, or it is a hypothesis — and this project
has shipped hypotheses as facts twice:

- `Company.all` was reported as unable to work against a live tenant. The API
  routes both `/companys` and `/companies`.
- `Request#run` grew handling for a top-level array response. No list endpoint
  has ever returned one.

Both were inferred from [the collection](../api/postman-collection.md) and stated
as observed. The habit worth keeping is narrow: **the collection settles verbs
and paths; only the API settles fields and behaviour.**

# The read-only probe

`claude_scripts/probe_api_shapes/` walks every documented read and reports
**shape only** — status, whether the body is empty, top-level type, key names,
counts. Never values, so its output is safe to paste into an issue.

```bash
CONEXA_API_HOST=https://yourtenant.conexa.app \
CONEXA_API_TOKEN=... \
ruby claude_scripts/probe_api_shapes/probe.rb
```

Three layers keep it safe, deliberately redundant because it talks to production:
[read-only mode](../architecture/read-only-mode.md) is on, only `GET` requests are
constructed, and no money-moving endpoint appears in its list. The API allows 60
requests per minute; the script waits between calls.

For one-off questions on the Checkbits tenant, the `ckbt-conexa` skill already
holds the key and answers `conexa.py raw "/rota"` without exporting anything.

# What is off limits

Never probed, in any mode: `PATCH /charge/settle/:id`, `PATCH /contract/end/:id`,
`PATCH /recurringSale/end/:id`, `POST /room/booking/:id/checkout`, and every
`DELETE`. Settling moves money and can issue an NF-e.

A write mode was designed and dropped. It would have used a sentinel id that does
not exist — the API distinguishes "route does not exist" from "resource does not
exist", so the verb fixes could have been confirmed without performing anything —
and it was still not worth breaking the read-only rule for the one question it
would have answered.

# Reading the errors

The API's 404s say three different things, and telling them apart is most of the
diagnostic value:

| Message | Means |
|---------|-------|
| `Unable to resolve the request "api/v2/..."` | the route does not exist |
| `The system is unable to find the requested action "view"` | the controller exists, that action does not |
| `This X does not exist or you have no permission to access it` | resource-level, or permissions |

Only the third is about your account. That distinction is what settled whether
[`CreditCard` reads exist](../architecture/resource-catalog.md) — they do not —
rather than being switched off for one tenant.

Enums are discoverable the same way: a `400` on an unrecognised filter value names
the accepted set, so `status=pending` answers with the real list instead of
requiring a guess. That is how
[the status predicates](../defects/status-predicates-read-fields-that-do-not-exist.md)
were finally pinned down.

# What has been settled so far

| Question | Answer | When |
|----------|--------|------|
| List envelope | `{data, pagination: {hasNext, limit, offset}}`, uniform | 2026-08-12 |
| Any top-level array response? | No | 2026-08-12 |
| `page` honoured? | Validated, then ignored — always offset 0 | 2026-08-07 |
| `/companys` vs `/companies` | Both route | 2026-08-12 |
| `/creditCard` reads | Do not exist | 2026-08-12 |
| `Contract` open/closed | `isActive`; there is no `status` field | 2026-08-13 |
| `Charge.status` values | `unpaid`, `paid`, `cancelled`, `negotiated`, +5 | 2026-08-13 |

Still open, because answering it requires a write: whether a successful write ever
answers `200 {}` rather than `204` with no body. The gem handles both.

# Citations

[1] `claude_scripts/probe_api_shapes/README.md`.
[2] Probes run read-only against the Checkbits production tenant, 2026-08-12 and 2026-08-13.
