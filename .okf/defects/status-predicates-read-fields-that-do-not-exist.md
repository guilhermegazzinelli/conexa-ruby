---
type: Defect
title: Status predicates read fields the API never sends
description: Contract#active? compared a status field contracts have never had, and Charge#pending?/#overdue? compared values the API rejects — all three answered false unconditionally.
status: resolved
tags: [contract, charge, api-contract, testing]
timestamp: 2026-08-13T18:00:00Z
---

> **Resolved in 0.2.1** (issue #23). `Contract#active?`/`#ended?` read `is_active`;
> `Charge#unpaid?`/`#cancelled?` replace the two that never matched. The contract
> spec now checks modelled attributes against documented responses, not only verbs
> and paths.

# Overview

Three predicates compared `status` against values that do not exist:

```ruby
Contract#active?   status == 'active'     # contracts have no status field at all
Charge#pending?    status == 'pending'    # the API rejects `pending`
Charge#overdue?    status == 'overdue'    # and `overdue`
```

All three answered `false` unconditionally. `Charge#paid?` and every `Sale`
predicate were correct, which is probably how these survived — the pattern looked
uniform and three quarters of it worked.

# Validated against a live tenant

The fix was checked read-only before publishing, and that validation produced the
number worth carrying: **44 of the first 100 contracts on that tenant are active
with an `end_date` set.** Deriving "ended" from the presence of `end_date` — the
obvious shortcut for anyone who cannot trust `active?` — is therefore wrong for
nearly half the base, and wrong in the direction that writes. The caveat was
written as an edge case. It is not one.

**Prefer `ended?` over `!active?`.** Ruby cannot tell `nil` from `false` through
`!`, so `!active?` reads an *unknown* contract as closed — the same "unknown
treated as inactive" this fix set out to remove. Only `ended?`, or an explicit
`.nil?`, preserves the distinction.

# The follow-ups

Reviewing the fix turned up four more, all of the same family: a claim stated with
more confidence than its evidence supported.

- **`Charge::STATUSES` was the filter list, not the field list.** Built from the
  400 the API returns for an unrecognised filter — and the comment called it "the
  API's own, not a guess", when that message had been truncated in the terminal
  and the tail completed from memory. The field can also hold `excluded`, which
  `?status=` does not accept. Now `STATUSES` (10) and `FILTERABLE_STATUSES` (9).
- **`REFERENCE.md` still taught `contract.status` and `charge.pending?`** in seven
  places. The code and the CHANGELOG were fixed; the document a consumer actually
  reads was not.
- **Deprecations warned per call** — a hundred identical lines from one
  `charges.select(&:pending?)`. `Conexa::Deprecation` now warns once per process.
- **The handoff's own read-only check did not reach the guard** (#26), and would
  have required pointing a settlement at a real charge to test the brake. See
  [read-only mode](../architecture/read-only-mode.md).

# Why it is the dangerous kind

`Contract#active?` exists to answer *does this customer already have an active
contract?* That is the guard between doing nothing and **creating a second one**.
Answering `false` biases every caller toward the write. A downstream billing
integration mirroring the same `status == "active"` test never matched, fell
through to `data.first`, and linked customers to their **oldest** contract — the
closed one.

`Charge#pending?` is the same shape: "is this charge still open?" is what a
dunning run asks before sending.

# What the API actually sends

| Resource | Field | Values |
|----------|-------|--------|
| `Contract` | `isActive` (boolean) | — no `status` field exists |
| `Charge` | `status` | `unpaid`, `negotiated`, `generatedByNegotiation`, `cancelled`, `paid`, `denied`, `thirdPartyCompany`, `protested`, `juridical` |
| `Sale` | `status` | `paid`, `billed`, `cancelled`, `notBilled`, `deducted` |

The enums are knowable without guessing: the API validates the `status` filter and
names the accepted set in the `400`.

**`endDate` does not substitute for `isActive`.** An active contract can carry a
future closing date — contract 281 on the live tenant is `isActive: true` with
`endDate: 2026-11-30`. Deriving "ended" from the presence of `end_date` inverts
the answer.

# Why the contract layer missed it

`spec/contract/api_contract_spec.rb` compared **verbs and paths** and never looked
at payloads. A predicate could therefore read a field that has never existed and
stay green through four review rounds and a release.

0.2.1 adds `PostmanCollection.response_fields` and asserts that the attributes the
predicates depend on appear in a documented response. It is a **union across
examples**, never an exact set — see
[the collection's limits](../api/postman-collection.md): the live API returns
`isActive` on `GET /contract/:id` and no export documents it, so an exact-match
check would report a real field as missing.

# Citations

[1] [Issue #23](https://github.com/guilhermegazzinelli/conexa-ruby/issues/23)
[2] Enums and the `isActive` behaviour verified read-only against a production tenant, 2026-08-13.
[3] The documentation gap was reported to Conexa the same day.
