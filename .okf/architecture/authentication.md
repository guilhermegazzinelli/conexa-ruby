---
type: Component
title: Authentication and configuration
description: One live auth path (a static Bearer token from Configuration) and one dead legacy path (JWT multi-client TokenManager) ship in the same gem.
tags: [auth, legacy]
timestamp: 2026-08-11T18:40:00Z
---

# Overview

The gem contains **two** authentication systems. Only the first works.

## Live path — `Configuration` + Bearer token

```ruby
Conexa.configure do |config|
  config.api_host  = 'https://mycompany.conexa.app'
  config.api_token = ENV['CONEXA_API_TOKEN']
end
```

`Conexa::Configuration` exposes exactly two accessors, `api_token` and
`api_host`. `Conexa.api_endpoint` appends the fixed suffix
`/index.php/api/v2`, and `Request#request_params` sets
`Authorization: Bearer <api_token>` on every non-auth call. There is no refresh,
expiry or rotation — the token is the Application Token created in Conexa under
**Config > Integrações > API / Token**.

There is no `config.subdomain` — `README.md` used to configure one and raised
`NoMethodError`; [fixed in 0.2.0](../defects/readme-quickstart-uses-nonexistent-subdomain.md).

0.2.0 adds a third setting, `read_only` — see [Read-only mode](read-only-mode.md).

## Removed in 0.2.0 — `Client` / `Authenticator` / `TokenManager`

A three-class JWT system for holding several PDV/e-commerce clients behind
symbolic keys, with a mutex-guarded singleton and automatic refresh. It was **unreachable**: every entry point read `Conexa.credentials`,
`Conexa.secret_key`, `Conexa.access_key`, `Conexa.client_id` or
`Conexa.default_client_key`, and *none of those methods exist* on the `Conexa`
module. It also targets `/pdvauth` and `/refresh-token`, which are not part of
API v2.

See [dead legacy TokenManager](../defects/dead-legacy-token-manager.md) for why
the specs are green anyway.

# Citations

[1] `lib/conexa/configuration.rb`, `lib/conexa.rb`, `lib/conexa/authenticator.rb`, `lib/conexa/token_manager.rb` — gem v0.1.1.
[2] `README.md` lines 27–30 and 43–46 (broken `config.subdomain`), verified 2026-08-11.
