---
type: Defect
title: Empty response body raises NoMethodError after a successful write
description: A 2xx with an empty or null body decodes to nil and Request#run calls .dig on it — so a completed settlement is reported to the caller as a crash.
status: resolved
tags: [errors, charge, http, issue-20]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** Request#run now returns `{}` for an empty, whitespace or `null` body at any status, and handles a top-level array. Covered by `spec/conexa/empty_response_spec.rb`.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

The most damaging of the confirmed defects, and the one to fix first.

`lib/conexa/request.rb:26-30`:

```ruby
def run
  response = RestClient::Request.execute request_params
  response = MultiJson.decode response.body
  return { data: response.dig("data") || response, pagination: response.dig("pagination") }
```

The success path assumes the body decodes to a Hash. When it does not, the
caller gets a raw `NoMethodError` — which is **not** a `Conexa::ConexaError`, so
it escapes any `rescue Conexa::ConexaError` a consumer wrote.

# Why it fires on the happy path

This is not an edge case. `PATCH /charge/settle/:id` **documents** `204` with an
empty body as its success response, and `PATCH /contract/end/:id` answers `200`
with an empty body. Both complete server-side before the exception is raised.

The consequence in a billing integration is a false failure that invites a retry:
settling the same charge twice, or compensating for a settlement that already
happened. In the incident behind
[issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20), two
charges were settled and two NF-e issued while the client code reported failure.
See
[Charge settlement](../api/charge-settlement.md).

# The 204 guard is dead code

`request.rb:52-55` looks like it handles this:

```ruby
rescue MultiJson::ParseError
  return {} if response.code == 204
```

It never runs. With the Oj adapter this project resolves,
`MultiJson.decode("")` returns `nil` **without raising** `ParseError` — verified
for `""`, `"  "` and `"null"`. So even a legitimate `204` falls through to
`nil.dig` and raises. The rescue only ever catches genuinely malformed JSON.

# Reproduction

Verified 2026-08-11 against gem v0.1.1; all three cases raise `NoMethodError:
undefined method 'dig' for nil`:

```ruby
stub_request(:patch, "#{BASE}/charge/settle/555").to_return(status: 200, body: "")
Conexa::Request.patch("/charge/settle/555", params: {}).run   # NoMethodError

stub_request(:delete, "#{BASE}/contract/789").to_return(status: 204, body: "")
Conexa::Request.delete("/contract/789").run                   # NoMethodError — the 204 guard does not fire
```

# Suggested fix

Guard the decoded value for **any** status, and stop relying on `ParseError` to
detect emptiness:

```ruby
body = response.body.to_s
return {} if body.strip.empty?

decoded = MultiJson.decode(body)
return {} if decoded.nil?

{ data:       decoded.is_a?(Hash) ? (decoded["data"] || decoded) : decoded,
  pagination: decoded.is_a?(Hash) ? decoded["pagination"] : nil }
```

This also covers the non-Hash case — `decoded.dig` on an Array raises too.

Fixing it changes the outcome of every action method from "raises" to `{}`.
Any caller currently treating `NoMethodError` as a de-facto success signal needs
checking before the change lands. See [Error model](../architecture/error-model.md).

# Citations

[1] [Issue #20 — Contract API: wrong verb and field on end_contract, NoMethodError on empty responses](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20)
[2] `lib/conexa/request.rb` v0.1.1; MultiJson 1.19.1 resolving to the Oj adapter.
[3] Documented `204` success response: [Vendored Postman collection](../api/postman-collection.md), *Charge > /charge/settle/:id*.
