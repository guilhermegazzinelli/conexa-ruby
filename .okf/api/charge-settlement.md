---
type: Endpoint
title: Charge settlement
description: PATCH /charge/settle/:id — a money-moving, NF-e-issuing write whose documented success response is 204 with an empty body, which the gem cannot parse.
resource: https://{tenant}.conexa.app/index.php/api/v2/charge/settle/{id}
tags: [charge, api-contract, errors]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

Settling a charge marks it paid, and in a configured tenant it also **issues an
NF-e**. It is the least idempotent-friendly call in the API: a spurious retry
settles twice and issues two invoices. That makes the gem's handling of its
response a financial concern, not a cosmetic one.

# Schema

`PATCH /charge/settle/:id`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `settlementDate` | `yyyy-MM-dd` | yes | |
| `receivingMethod` | object | yes | |
| `receivingMethod.id` | integer | yes | from `GET /receivingMethods` |
| `receivingMethod.installmentsQuantity` | integer | yes | |
| `accountId` | integer | yes | from `GET /accounts`; bound to the charge |
| `paidAmount` | decimal | no | defaults to the charge amount, without interest |
| `sendEmail` | boolean | no | defaults to `false` |

## The success response is `204` with an empty body

That is what the collection documents, and it is what production returns. The
gem's `Request#run` decodes it to `nil` and then calls `.dig` on it — so **every
successful settlement raises `NoMethodError`** after the money has moved. See
[empty response body raises NoMethodError](../defects/empty-body-nomethoderror.md).
This has already caused two double-settlements and two NF-e in production.

## Documented business-rule failures (`422`, `{code, message}` shape)

| Code | Meaning |
|------|---------|
| `CHARGE_11` | only charges with an open status can be settled |
| `CHARGE_06` | installment count exceeds the maximum for the configured payment method |

`CHARGE_11` is the one a retry hits: the second attempt at an already-settled
charge fails with it. That is a useful signal — a consumer that recognises
`CHARGE_11` can treat it as "already done" rather than a hard error.

The gem's `Charge#settle` sends `POST`, which 404s before reaching any of this:
[wrong HTTP verb on action endpoints](../defects/wrong-verb-on-action-endpoints.md).

# Citations

[1] [Vendored Postman collection](postman-collection.md) — *Charge > /charge/settle/:id*, documented responses `204`, `400`, `404`, `422`.
[2] Production double-settlement incident, 2026-08-07 — [issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20).
