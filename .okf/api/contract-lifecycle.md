---
type: Endpoint
title: Contract create and end
description: POST /contract and PATCH /contract/end/:id — the conditional dueDay rule, the atomic create-and-settle option, and the fact that "end" also amends and reopens.
resource: https://{tenant}.conexa.app/index.php/api/v2/contract
tags: [contract, api-contract]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

Contracts are the recurring-billing primitive: a customer plus a plan plus a
frequency, which generates sales on a schedule. Two operations carry almost all
the difficulty.

# `PATCH /contract/end/:id`

**It is not only a terminator.** The documented purpose is *"encerra um contrato
ativo **ou atualiza a data de encerramento** de um contrato"* — it closes *and*
amends. Passing a future date to an already-closed contract **reopens** it
(verified in production, then reverted). Treat it as "set the end date", not
"end".

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `date` | `yyyy-MM-dd` | **yes** | the closing date |
| `reasonId` | integer | no | from *Listagem de Contratos > Outros Cadastros > Motivo de Encerramento de Contrato* |
| `unlinkCustomer` | boolean | no | unlinks DDRs, mailboxes, extensions and recurring sales. Requires `date <= today` **and** no other active contracts. Ends *all* the customer's recurring sales and cancels their uninvoiced sales. |

Documented failure worth surfacing: `CONTRACT_RECURRING_SALE_23` — a contract
cannot be closed retroactively past a day that already has invoiced sales.

On success this endpoint may answer with an **empty body** — see
[empty response body raises NoMethodError](../defects/empty-body-nomethoderror.md).

The gem's `Contract#end_contract` gets both the verb and the field name wrong:
[wrong HTTP verb on action endpoints](../defects/wrong-verb-on-action-endpoints.md).

# `POST /contract`

Required: `planId`, `customerId`, `paymentFrequency`
(`monthly`|`bimonthly`|`quarterly`|`semester`|`yearly`), `startDate`.

Three rules that are not obvious from the field table:

**`dueDay` is conditionally required *and* conditionally forbidden.** Required on
a customer's **first** contract (or when they use automatic invoicing); rejected
on every later one, which inherits the customer's `defaultDueDay`. The rejection
is a documented `422`:

```json
{ "message": "It was not possible to process your request",
  "errors": [{ "code": "CONTRACT_RECURRING_SALE_10",
               "message": "The due day can not be informed for customers who already have a contract" }] }
```

Because that shape is a `{code, message}` business-rule error, consumers that
only render `{field, messages}` show it as a blank string — which is how it
survived eight blind attempts in production. See
[error shapes are not normalised](../defects/error-shape-normalisation-gap.md).

**`generateSales: "firstOccurrenceSettleRetroactive"` collapses three calls into
one.** It generates *and settles* retroactive charges atomically, and then
requires `expenseSettlement.receivingMethodId` and `expenseSettlement.accountId`.
The alternative — create contract, create charge, settle — is three network
round-trips, each individually failable. Not modelling this pushes users onto the
fragile path.

**`costCenterId` is not accepted on create** (`400 — does not exist or is not
available`), even though it comes back when you read the contract.

Also documented and unmodelled: `firstDueDate`, `prorataType`
(`startOfMonth`|`notCalculate`|`perDueDate`), `refund` (explicit `null` opts out
even when the plan configures one), `membershipFee`, `fidelityDate`, `sellerId`,
`nfseDescription`, `complementaryServices[]`, `extraFields`. See
[Contract creation fields are not modelled](../defects/contract-creation-fields-gap.md).

# Citations

[1] [Vendored Postman collection](postman-collection.md) — *Contract > /contract* and *Contract > /contract/end/:id*.
[2] Reopen-on-future-date and `costCenterId` rejection verified against a production tenant, 2026-08-07 — [issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20).
