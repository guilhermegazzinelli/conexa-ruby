---
type: Defect
title: Contract creation fields are not modelled
description: POST /contract documents a dozen fields the gem neither exposes nor validates, including a conditionally-forbidden dueDay and an option that makes create-charge-settle atomic.
status: resolved
tags: [contract, api-contract, issue-20]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** Documented in YARD on `Conexa::Contract`, including the conditional `dueDay` rule and the atomic `firstOccurrenceSettleRetroactive` flow. No code was needed beyond the array-camelization fix; `ResponseError#api_error_codes` makes `CONTRACT_RECURRING_SALE_10` actionable.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

`Conexa::Contract` is a bare `Model` — four helper methods and no knowledge of
what `POST /contract` accepts. Because the
[object model](../architecture/object-model.md) passes any hash straight through,
this is not *blocking*: a caller who knows the field names can send them. The gap
is that nothing tells them, and two of the fields have rules no one guesses.

The full documented body is in
[Contract create and end](../api/contract-lifecycle.md). The two that matter:

# `dueDay` is required *and* forbidden, depending on the customer

Required on a customer's first contract; rejected (`422
CONTRACT_RECURRING_SALE_10`) on every later one. Code that always sends `dueDay`
works during onboarding and fails forever after — a failure mode that only
appears in production, months later, per customer.

This one cost eight blind attempts, because the `{code, message}` error shape
rendered as an empty string on the way out. That is a separate defect:
[error shapes are not normalised](error-shape-normalisation-gap.md).

At minimum the gem should document the rule; better, guard it or map the code to
a named exception.

# `generateSales: "firstOccurrenceSettleRetroactive"`

Generates *and settles* retroactive charges in the same request, requiring
`expenseSettlement.receivingMethodId` and `expenseSettlement.accountId`. It
collapses create-contract → create-charge → settle into one atomic call. Not
modelling it pushes users onto the three-call path, where each step can fail
independently — and where step three is
[charge settlement](../api/charge-settlement.md), the call that currently raises
on success.

# Also unmodelled

`firstDueDate`, `prorataType` (`startOfMonth`|`notCalculate`|`perDueDate`),
`refund` (explicit `null` opts out even when the plan configures one),
`membershipFee`, `fidelityDate`, `sellerId`, `nfseDescription`,
`complementaryServices[]`, `extraFields`.

For symmetry: `costCenterId` is **not** accepted on create (`400 — does not exist
or is not available`) even though it is present when the contract is read back.

# Citations

[1] [Issue #20, item 4](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20)
[2] [Vendored Postman collection](../api/postman-collection.md) — *Contract > /contract*, including the documented `422 CONTRACT_RECURRING_SALE_10` example response.
