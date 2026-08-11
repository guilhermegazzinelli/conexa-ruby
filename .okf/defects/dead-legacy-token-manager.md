---
type: Defect
title: Dead legacy TokenManager ships in the gem
description: Client, Authenticator and TokenManager call five Conexa module methods that do not exist — the classes cannot run, and their specs are green only because they stub the missing methods into being.
status: resolved
tags: [auth, legacy, testing]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** `Client`, `Authenticator`, `TokenManager` and `OrderCommon` were deleted along with the `jwt` dependency. `verify_partial_doubles = true` now prevents the class of spec that hid this.
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

`Conexa::OrderCommon` belongs to the same era — its methods thread a `client_key`
through to these classes. See the note in the
[resource catalogue](../architecture/resource-catalog.md).

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

# Decision needed

Two coherent options, and the current state is neither:

1. **Remove it** — delete the three classes, `OrderCommon`, and their specs. This
   is a breaking change only for code that already cannot run.
2. **Complete it** — add the five accessors to `Conexa`/`Configuration` and point
   the flow at a real v2 auth endpoint.

Whichever is chosen, do it before the next minor release; shipping unreachable
auth code in a billing gem is a standing invitation to a confusing incident.

# Citations

[1] `lib/conexa/authenticator.rb`, `lib/conexa/token_manager.rb`, `lib/conexa.rb`, `lib/conexa/order_common.rb` — gem v0.1.1.
[2] `NoMethodError` and the five `respond_to?` results reproduced 2026-08-11.
