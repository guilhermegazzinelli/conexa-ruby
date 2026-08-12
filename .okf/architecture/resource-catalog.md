---
type: Reference
title: Resource catalogue — gem classes vs documented endpoints
description: Every Model subclass, the URL it emits, and whether the published collection documents it — the audit table that surfaced the URL and verb defects, now enforced in CI.
tags: [api-contract, http]
timestamp: 2026-08-12T23:59:00Z
---

# Overview

21 classes inherit from `Conexa::Model`. Because URLs are
[derived from the class name](request-pipeline.md), the only way to know whether
a resource is correct is to compare what it emits against
[the published collection](../api/postman-collection.md).

This table is that comparison, regenerated 2026-08-11 against gem **v0.2.0**.
It is no longer a manual exercise: `spec/contract/api_contract_spec.rb` performs
the same sweep on every CI run and fails on a mismatch — see
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md).

# Schema

`ok` = the collection documents that exact path and verb.

| Class | Emits | Documented? |
|-------|-------|-------------|
| `Account` | `GET /accounts` | not documented, **verified to exist** (2026-08-12) |
| `Account` | `GET /account/:id` | ok |
| `Bill` | `GET /bills`, `GET /bill/:id` | ok |
| `BillCategory` | `GET /billCategories`, `GET /billCategory/:id` | ok |
| `BillSubcategory` | `GET /billSubcategories`, `GET /billSubcategory/:id` | ok |
| `Charge` | `GET /charges`, `GET /charge/:id` | ok |
| `Company` | `GET /companies`, `GET /company/:id` | ok |
| `Contract` | `GET /contracts`, `GET /contract/:id` | ok |
| `CostCenter` | `GET /costCenters`, `GET /costCenter/:id` | ok |
| `CreditCard` | `GET /creditCard`, `GET /creditCard/:id` | **verified NOT to exist** (2026-08-12) — see below |
| `Customer` | `GET /customers`, `GET /customer/:id` | ok |
| `InvoicingMethod` | `GET /invoicingMethods`, `GET /invoicingMethod/:id` | ok |
| `PaymentMethod` | `GET /paymentMethods`, `GET /paymentMethod/:id` | ok |
| `Person` | `GET /persons`, `GET /person/:id` | ok |
| `Plan` | `GET /plans`, `GET /plan/:id` | ok |
| `Product` | `GET /products`, `GET /product/:id` | ok |
| `ReceivingMethod` | `GET /receivingMethods`, `GET /receivingMethod/:id` | ok |
| `RecurringSale` | `GET /recurringSales`, `GET /recurringSale/:id` | ok |
| `RoomBooking` | `GET /room/bookings`, `GET /room/booking/:id` | ok |
| `Sale` | `GET /sales`, `GET /sale/:id` | ok |
| `ServiceCategory` | `GET /serviceCategories`, `GET /serviceCategory/:id` | not documented, **verified to exist** (2026-08-12) |
| `Supplier` | `GET /suppliers`, `GET /supplier/:id` | not documented, **verified to exist** (2026-08-12) |

`Company` emitted `/companys` and now emits the documented `/companies` — but the
live API [routes both](../defects/wrong-url-for-company-list.md), so this was an
inconsistency, not the 404 it was first reported as. Resources with irregular
English plurals override anyway; `RoomBooking`, `Account`, `ServiceCategory`,
`RecurringSale` and now `Company` do.

**`CreditCard` reads do not exist.** Verified 2026-08-12: `GET /creditCard` answers
`404 Unable to resolve the request` and `GET /creditCard/:id` answers `404 unable
to find the requested action "view"`. The collection documents only
`POST /creditCard`, and the API agrees. `CreditCard.all`/`.find` are therefore
dead surface — a caller gets `Conexa::NotFound`, which is at least an honest
answer, but the methods should not be advertised.

The "not documented" rows are **not** bugs — the collection is incomplete for
several read endpoints. As of 2026-08-12 they are no longer merely assumed: a
read-only probe against the production tenant confirmed `/accounts`,
`/suppliers` and `/serviceCategories` return real data, and that `/creditCard`
does not. They stay on the contract spec's explicit allowlist, which is what makes
a **new** undocumented path fail instead of slipping through.

`OrderCommon` was in this table until 0.2.0, targeting `/order/:id` and
`/order/:id/refund`. **API v2 documents no `/order` endpoint at all**, which is
why it went — not because it was broken: unlike
[the JWT auth classes removed alongside it](../defects/dead-legacy-token-manager.md),
it executed and issued a real `DELETE`.

# Action endpoints

Beyond CRUD, these methods build their own path *and* pick their own verb. This
is where the verb defects lived; the ACTIONS table in
`spec/contract/api_contract_spec.rb` mirrors this list and fails if a new
hand-written endpoint is added without a row.

| Method | Emits | Documented |
|--------|-------|------------|
| `Charge#settle` | `PATCH /charge/settle/:id` | ok (was `POST`) |
| `Contract#set_end_date` | `PATCH /contract/end/:id` | ok (was `POST`) |
| `RecurringSale#end_recurring_sale` | `PATCH /recurringSale/end/:id` | ok (was `POST`) |
| `Charge#pix` | `GET /charge/pix/:id` | ok |
| `Charge#cancel` | `POST /charge/cancel/:id` | not documented |
| `Charge#send_email` | `POST /charge/sendEmail/:id` | not documented |
| `RoomBooking#cancel` | `PATCH /room/booking/:id/cancel` | ok |
| `RoomBooking#checkout` | `POST /room/booking/:id/checkout` | ok |
| `RoomBooking.checkin` / `.standalone_checkout` | `POST /checkin`, `POST /checkout` | ok |

See [wrong HTTP verb on action endpoints](../defects/wrong-verb-on-action-endpoints.md).

# Regenerating

Only needed after refreshing the collection; the contract spec covers day-to-day
drift.

```bash
bundle exec rspec spec/contract/api_contract_spec.rb
```

# Citations

[1] Generated from `lib/conexa/resources/*.rb` (v0.2.0) against `docs/postman-collection.json`, 2026-08-11.
