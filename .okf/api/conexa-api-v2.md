---
type: Service
title: Conexa API v2
description: The upstream REST API this gem wraps — a per-tenant subdomain, a Bearer application token, and 68 documented operations.
resource: https://{tenant}.conexa.app/index.php/api/v2
tags: [api-contract, http]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

Conexa is a Brazilian coworking / recurring-billing platform. Each customer gets
a tenant subdomain, and the v2 REST API lives at a fixed suffix under it:

```
https://{tenant}.conexa.app/index.php/api/v2
```

The `/index.php` segment is not incidental — it is hard-coded in
`Conexa.api_endpoint` and is part of every real URL.

# Conventions

| Aspect | Convention |
|--------|-----------|
| Auth | `Authorization: Bearer <application token>`, created in Conexa under **Config > Integrações > API / Token**. No refresh flow. |
| Casing | camelCase throughout, request and response (`customerId`, `dueDate`). |
| Envelope | `{"data": …}`, plus `{"pagination": {limit, offset, hasNext}}` on list endpoints. |
| Singular/plural | Read-one and write endpoints are singular (`/charge/:id`); list endpoints are plural (`/charges`) — but the plural is the **English** plural, not `+s`. `/companies`, not `/companys`. |
| Actions | Sub-path plus a verb: `PATCH /contract/end/:id`, `PATCH /charge/settle/:id`. Actions are consistently `PATCH`, never `POST`. |
| Errors | Two shapes — see [Error model](../architecture/error-model.md). |

## Behaviours that are not in the reference tables

- **Successful writes may answer `200` with an empty body.** Confirmed on
  `PATCH /charge/settle/:id` and `PATCH /contract/end/:id`. The operation
  completes server-side; only the body is empty. This breaks the gem — see
  [empty response body raises NoMethodError](../defects/empty-body-nomethoderror.md).
- **`page` is validated and then ignored** on list endpoints, which always answer
  `offset: 0`. See
  [page is accepted and silently ignored](../defects/page-param-silently-ignored.md).
- **`PATCH /contract/end/:id` is not only a terminator** — it also amends an
  existing end date, and a future date on a closed contract reopens it. See
  [Contract lifecycle](contract-lifecycle.md).

The authoritative field-level reference is
[the published Postman collection](postman-collection.md), vendored in this repo.

# Citations

[1] [Conexa API v2 public documentation](https://documenter.getpostman.com/view/25182821/2s93RZMpcB)
[2] Behaviours verified against a production tenant, 2026-08-07 — [issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20).
