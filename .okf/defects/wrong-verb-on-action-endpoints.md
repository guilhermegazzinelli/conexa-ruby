---
type: Defect
title: Wrong HTTP verb on action endpoints
description: Three action methods send POST where the API documents PATCH, so they 404 — and end_contract also sends endDate where the documented field is date.
status: resolved
tags: [http, api-contract, issue-20]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** All three methods send `PATCH`, and `end_contract` sends the documented `date`/`reasonId`/`unlinkCustomer` (`end_date:` survives as a deprecated alias). `Contract#set_end_date` is the new primary name. Covered by `spec/conexa/action_endpoints_spec.rb` and enforced by `spec/contract/api_contract_spec.rb`.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

Conexa API v2 uses `PATCH` for every action endpoint. The gem uses `POST` for
three of them. Each one 404s against the live API:

| Method | Emits | Documented |
|--------|-------|------------|
| `Contract#end_contract` | `POST /contract/end/:id` | `PATCH /contract/end/:id` |
| `Charge#settle` | `POST /charge/settle/:id` | `PATCH /charge/settle/:id` |
| `RecurringSale#end_recurring_sale` | `POST /recurringSale/end/:id` | `PATCH /recurringSale/end/:id` |

[Issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20) reports
the first. The other two are the same defect in the same
shape and were found by sweeping the gem against the collection — see the action
table in the [resource catalogue](../architecture/resource-catalog.md).
`Charge#settle` is the more consequential of the two additions, since settlement
is [the money-moving call](../api/charge-settlement.md).

```
Conexa::Contract.end_contract(1105, { end_date: "2026-07-12" })
# => Conexa::ResponseError: 404 Not Found
#    Unable to resolve the request "api/v2/contract/end/1105".
```

# `end_contract` also sends the wrong field

Even with the verb corrected, the payload is wrong. The gem's public signature is
`end_contract(id, end_date:, reason:)`, which
[camelizes](../architecture/request-pipeline.md) to `endDate`. The documented
body is `date`, `reasonId`, `unlinkCustomer`:

```
Conexa::Request.patch("/contract/end/1105", params: { end_date: "2026-07-12" }).run
# => 400 Field validation error => [
#      {"field"=>"endDate", "messages"=>["Failed to set, \"endDate\" field does not exist or is not available in the company"]},
#      {"field"=>"date",    "messages"=>["Date cannot be blank"]}
#    ]

Conexa::Request.patch("/contract/end/1105", params: { date: "2026-07-12" }).run   # works
```

`unlinkCustomer` is not modelled at all, and the method name understates the
endpoint — see [Contract create and end](../api/contract-lifecycle.md).

# Why the specs are green

`spec/integration/contract_spec.rb:116` stubs `stub_request(:post, …)`. The stub
was written from the implementation, so it agrees with the bug and the suite
passes. This is the general pattern in
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md).

# Reproduction

Verified 2026-08-11 against gem v0.1.1 by asserting the verb and body actually
emitted, rather than stubbing the expected one:

```ruby
sent = nil
stub_request(:post, "#{BASE}/contract/end/789").with { |r| sent = r; true }…
Conexa::Contract.end_contract(789, { end_date: "2026-07-12" })
sent.method                    # => :post          (documented: :patch)
JSON.parse(sent.body).keys     # => ["endDate"]    (documented: "date")
```

# Suggested fix

- `Request.patch` in all three methods.
- `end_contract`: send `date:`; accept `end_date:` as a deprecated alias; add
  `reason_id:` and `unlink_customer:`.
- Add request-level contract tests asserting verb and serialized payload, so the
  next drift fails a test rather than a production write.

# Citations

[1] [Issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20)
[2] [Vendored Postman collection](../api/postman-collection.md) — *Contract > /contract/end/:id*, *Charge > /charge/settle/:id*, *Recurring Sale > /recurringSale/end/:id*.
