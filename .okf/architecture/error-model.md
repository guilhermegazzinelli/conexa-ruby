---
type: Component
title: Error model
description: The exception taxonomy raised by Request#run, and how the API's two different error shapes land in it.
tags: [errors, http]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

All error classification happens in one place — the `rescue` chain of
`Request#run` (`lib/conexa/request.rb`). Resource classes never raise on their
own.

# Schema

| Class | Raised when | Carries |
|-------|-------------|---------|
| `Conexa::ConexaError` | — | base class for everything below |
| `Conexa::NotFound` | HTTP 404 with a decodable body | the parsed response, request params |
| `Conexa::ResponseError` | any other HTTP error **with** a `message` key; also any undecodable error body | request params, the RestClient error, a composed message |
| `Conexa::ValidationError` | an HTTP error body **without** a `message` key | a list of `ParamError` built from `response['message']` |
| `Conexa::ConnectionError` | `SocketError`, `RestClient::ServerBrokeConnection` | the underlying error |
| `Conexa::RequestError` | client-side guard failures (blank id, bad `limit`/`offset`) | — |
| `Conexa::MissingCredentialsError` | `TokenManager` cannot find a key | — |

`ValidationError`'s branch is close to unreachable in practice: it triggers only
when the body has no `message`, yet its constructor then maps over
`response['message']`. It is safe (`&.`) but yields an empty error list.

## The API answers errors in two shapes

This is the part that costs debugging time. Conexa API v2 returns:

```json
{"errors": [{"field": "date", "messages": ["Date cannot be blank"]}]}          // field validation
{"errors": [{"code": "CONTRACT_RECURRING_SALE_10", "message": "The due day…"}]} // business rule
```

`Request#run` stringifies the whole `errors` array into the exception message, so
the gem always surfaced both. What was missing was a structured accessor, which
left every consumer to reimplement the formatting and get the second shape wrong.
0.2.0 adds them to `ResponseError`:

| Method | Returns |
|--------|---------|
| `api_response` | the decoded error body |
| `api_errors` | `[{field:, code:, message:}]`, both shapes normalised |
| `api_error_codes` | `["CHARGE_11"]` — the part worth branching on |
| `api_error_messages` | one readable line per error |

`api_error_codes` is the one to reach for: `CHARGE_11` ("only charges with an
open status can be settled") is how a caller tells an already-settled charge from
a real failure. See
[error shapes are not normalised for consumers](../defects/error-shape-normalisation-gap.md).

## The success path used to raise too

Until 0.2.0 a 2xx with an empty body escaped this taxonomy entirely and raised a
raw `NoMethodError` that `rescue Conexa::ConexaError` did not catch — see
[empty response body raises NoMethodError](../defects/empty-body-nomethoderror.md).
It now returns `{}`.

0.2.0 also adds `Conexa::ReadOnlyError`, raised before a mutating request is sent
while [read-only mode](read-only-mode.md) is on.

# Citations

[1] `lib/conexa/errors.rb`, `lib/conexa/request.rb` — gem v0.1.1.
[2] Error shapes confirmed against [the published collection](../api/postman-collection.md) and live production traffic, 2026-08-07 ([issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20)).
