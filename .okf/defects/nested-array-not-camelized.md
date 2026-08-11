---
type: Defect
title: Nested arrays were not camelized
description: Util.camelize_hash recursed into hashes but treated an array as a scalar, so snake_case keys inside arrays of objects were sent untouched and rejected across ten endpoints.
status: resolved
tags: [api-contract, http]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** `Util.camelize_hash` delegates to a new `camelize_value`
> that recurses through both `Hash` and `Array`. Covered by
> `spec/conexa/nested_payload_spec.rb`.
>
> Found while planning the 0.2.0 fixes, not reported in issue #20 — it was
> invisible because no spec exercised an array-of-objects payload.

# Overview

`Util.camelize_hash` recursed into a nested `Hash` but fell through to the `else`
branch for an `Array`, passing it along untouched:

```ruby
Conexa::Util.camelize_hash(complementary_services: [{ product_or_service_id: 2113 }])
# => {complementaryServices: [{product_or_service_id: 2113}]}
#                              ^^^^^^^^^^^^^^^^^^^^^^ never converted
```

The API rejects it:

```
400 "complementaryServices.productOrServiceId — The product or service is not valid"
```

The outer key was converted, so the payload looked right at a glance, and the
failure named a field the caller believed they had sent.

# Reach

Ten documented endpoints across seven resources take arrays of objects. Only
those whose inner keys are multi-word actually broke, but the ones that did are
central:

| Resource | Field | Inner keys that broke |
|----------|-------|----------------------|
| `Contract` | `complementaryServices`, `productQuotas` | `productOrServiceId`, `productId` |
| `Plan` | `productQuotas`, `bookingModels`, `hourQuotas`, `paymentPeriodicities` | `productId`, `groupId` |
| `Person` | `devices` | `macAddress` |
| `Customer` | `extraFields` | — (single-word keys) |
| `Bill` | `costCenters` | — |
| `RoomBooking` | `visitors` | — |

This is what made
[the atomic create-and-settle flow](contract-creation-fields-gap.md) unreachable
in practice: `expenseSettlement` is a plain hash and worked, but any contract
carrying `complementaryServices` failed.

# Why nothing caught it

Every write spec used flat payloads. The gem's
[dynamic object model](../architecture/object-model.md) passes any hash straight
through without validation, so there is no schema to disagree with — the only way
to notice is to assert the serialized body, which is what
`spec/support/request_capture.rb` now makes cheap. See
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md).

# Citations

[1] `lib/conexa/util.rb` — gem v0.1.1 vs v0.2.0.
[2] Array-of-object bodies enumerated from [the vendored collection](../api/postman-collection.md), 2026-08-11.
