---
type: Defect
title: Dead legacy TokenManager ships in the gem
description: Client, Authenticator and TokenManager called five Conexa module methods that never existed, so any real use raised NoMethodError — and their specs stubbed those methods into being.
status: resolved
tags: [auth, legacy, testing]
timestamp: 2026-08-12T14:00:00Z
---

> **Resolved in 0.2.0.** `Client`, `Authenticator` and `TokenManager` were deleted along with the `jwt` dependency. `verify_partial_doubles = true` now prevents the class of spec that hid this. `OrderCommon` went in the same commit but for a different reason — see below; do not carry over the "could not execute" framing to it.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

`lib/conexa/authenticator.rb` and `lib/conexa/token_manager.rb` implement a
JWT-based, mutex-guarded, multi-client credential system for PDV and e-commerce
clients. It is loaded by `lib/conexa.rb` on every `require "conexa"` and it
cannot execute:

```ruby
Conexa::TokenManager.instance
# => NoMethodError: undefined method `credentials' for Conexa:Module
```

`Conexa.credentials`, `Conexa.secret_key`, `Conexa.access_key`,
`Conexa.client_id` and `Conexa.default_client_key` are all referenced and none is
defined — the module exposes only `configuration`, `configure` and
`api_endpoint`. Verified 2026-08-11: `Conexa.respond_to?` is `false` for all five.

The endpoints it targets (`/pdvauth`, `/refresh-token`) are not part of API v2
either. The live path is the Bearer token described in
[Authentication and configuration](../architecture/authentication.md).

## `OrderCommon` is the same era but not the same defect

It was removed in the same commit, and it is tempting to file it here — its
methods thread a `client_key` meant for these classes. But the framing does not
transfer, and the distinction is worth keeping straight:

|  | `Client` / `Authenticator` / `TokenManager` | `OrderCommon` |
|--|--|--|
| Could it run? | No — `NoMethodError` on the first line | **Yes.** It built `/order/7/refund` and issued a real `DELETE` |
| Why removed | Unreachable code | API v2 documents **no** `/order` endpoint |
| Risk of removal | None; no caller could have worked | Real: it was a public constant that executed |

So `OrderCommon` was removed for obsolescence, not inoperability. Two details
found while verifying it:

- Its backwards-compatible alias never worked. `OrderCommom = self` written
  *inside* the class body defines `Conexa::OrderCommon::OrderCommom`, not
  `Conexa::OrderCommom` — so the pre-0.1.0 name raised `NameError` from the
  rename onward, despite the changelog claiming the alias was kept.
- `refund` calls `underscored_class_name` and `url`, both **class** methods, from
  instance context. They fall into `ConexaObject#method_missing`, which returns
  `nil` for any unknown attribute, so the call silently degraded to an untyped
  `ConexaObject` instead of raising.

See the note in the [resource catalogue](../architecture/resource-catalog.md).

# Why the specs are green

`spec/conexa/token_manager_spec.rb` and `spec/conexa/authenticator_spec.rb` open
with:

```ruby
allow(Conexa).to receive(:secret_key).and_return("test_secret")
allow(Conexa).to receive(:access_key).and_return("test_access")
allow(Conexa).to receive(:client_id).and_return("test_client_id")
allow(Conexa).to receive(:default_client_key).and_return(:default)
allow(Conexa).to receive(:credentials).and_return(nil)
```

Partial-double verification is not enabled, so RSpec happily stubs methods that
do not exist. The stubs *create* the interface the code needs, and the suite
proves nothing about whether it exists in production. Turning on
`config.mock_with(:rspec) { |m| m.verify_partial_doubles = true }` would have
failed these specs on day one — see
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md).

# The decision taken

Two coherent options existed, and the pre-0.2.0 state was neither:

1. **Remove** the three classes and their specs — a breaking change only for code
   that already could not run.
2. **Complete** them — add the five accessors to `Conexa`/`Configuration` and
   point the flow at a real v2 auth endpoint.

0.2.0 removed them. Completing would have required an auth endpoint that API v2
does not document, and shipping unreachable auth code in a billing gem is a
standing invitation to a confusing incident.

# Citations

[1] `lib/conexa/authenticator.rb`, `lib/conexa/token_manager.rb`, `lib/conexa.rb`, `lib/conexa/order_common.rb` — gem v0.1.1.
[2] `NoMethodError` and the five `respond_to?` results reproduced 2026-08-11.
