---
type: Component
title: Read-only mode
description: A hard guard at Request#run that refuses every non-GET request, for the many cases where the gem is used to look rather than to change.
tags: [auth, http, errors]
timestamp: 2026-08-11T18:40:00Z
---

# Overview

Added in 0.2.0. Turning it on makes any request other than `GET` raise
`Conexa::ReadOnlyError` **before** it leaves the process:

```ruby
Conexa.configure { |c| c.read_only = true }   # or CONEXA_READ_ONLY=1

Conexa::Charge.all(status: 'pending')   # fine
Conexa::Charge.settle(789)              # Conexa::ReadOnlyError
```

# Why it exists

This gem talks to a billing system. Settling a charge moves money and, on a
configured tenant, issues an NF-e — see
[charge settlement](../api/charge-settlement.md). Meanwhile a large share of real
use is investigation: was this invoice paid, what is outstanding, reconcile the
dunning run against what finance recorded. Those two facts sit uncomfortably
together in one client.

The incident behind issue #20 was exactly this shape — a write that should not
have been repeated, repeated. The empty-body defect
([now fixed](../defects/empty-body-nomethoderror.md)) made a successful
settlement look like a failure, and the retry it invited settled twice. A
read-only client would have turned that into an immediate, harmless exception.

The other case it covers is the more mundane one: a script pointed at the wrong
tenant. `CONEXA_READ_ONLY=1` in a shell or CI job is cheaper than remembering to
be careful.

# Design

| Decision | Why |
|----------|-----|
| Guard lives in `Request#run` | The [single choke point](request-pipeline.md) every verb passes through — one condition instead of a check per resource. |
| Raises before `RestClient::Request.execute` | A blocked call must not reach the tenant at all, not even to be rejected there. |
| Authentication is exempt | `POST /auth` is not a mutation, and without the exemption read-only mode could not obtain a token. |
| Block form is thread-local | `Conexa.read_only { }` must not relax or tighten another thread's state, and must restore on exception. |
| `ReadOnlyError < ConexaError` | Callers that already rescue the gem's base error see it; it is not a surprise `RuntimeError`. |

The block form composes with the global setting rather than replacing it — a
thread-local `nil` falls through to `configuration.read_only`, so a block only
overrides for its own duration.

# What it does not do

It is a client-side guard, not a permission. Anything holding the same token can
still write; if the requirement is that a credential *cannot* write, that has to
come from a scoped token on the Conexa side. Read-only mode protects against
mistakes, not against intent.

# Citations

[1] `lib/conexa.rb` (`read_only?`, `read_only`), `lib/conexa/configuration.rb`, `lib/conexa/request.rb` (`enforce_read_only!`) — gem v0.2.0.
[2] `spec/conexa/read_only_spec.rb`.
