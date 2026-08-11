---
type: Defect
title: Error shapes are not normalised for consumers
description: The API returns two error shapes; the gem stringifies both into the exception message but offers no accessor, so consumers that format {field, messages} render business-rule errors as blank.
status: resolved
tags: [errors, issue-20]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** `ResponseError` gained `api_response`, `api_errors`, `api_error_codes` and `api_error_messages`. Covered by `spec/conexa/api_errors_spec.rb`.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

Conexa API v2 answers errors in two shapes:

```json
{"errors": [{"field": "date", "messages": ["Date cannot be blank"]}]}           // field validation, 400
{"errors": [{"code": "CONTRACT_RECURRING_SALE_10", "message": "The due day…"}]}  // business rule, 422
```

`Request#run` builds its message with `parsed_error['errors'].to_s`, so **the
gem's own exception does surface both** — verified 2026-08-11: raising on a
`{code, message}` body produces a message containing
`CONTRACT_RECURRING_SALE_10`. So this is not a data-loss bug in the gem.

The gap is one layer out. `Conexa::ResponseError` exposes no structured accessor
for `errors`, so every consumer reimplements the formatting — and the obvious
implementation handles only the first shape:

```ruby
rescue Conexa::ResponseError => e
  errors.map { |err| "#{err['field']}: #{err['messages'].join(', ')}" }   # blank for {code, message}
```

That is exactly what happened: `CONTRACT_RECURRING_SALE_10` displayed as an empty
string through eight attempts at
[creating a contract](contract-creation-fields-gap.md), while the information
needed to fix it was sitting in the response body.

# Suggested fix

A normaliser on `ResponseError` that collapses both shapes into one readable
list, plus a structured reader so consumers stop parsing the message string:

```ruby
class ResponseError < ConexaError
  def api_errors
    Array(parsed_body['errors']).map do |e|
      if e['field'] then { field: e['field'], message: Array(e['messages']).join('; ') }
      else               { code:  e['code'],  message: e['message'] }
      end
    end
  end

  def api_error_codes = api_errors.filter_map { _1[:code] }
end
```

`api_error_codes` is the part that turns documented codes into control flow —
`CHARGE_11` ("only open charges can be settled") is how a caller distinguishes
"already settled" from a real failure, which matters given
[the empty-body defect](empty-body-nomethoderror.md) makes spurious retries
likely today.

This requires retaining the parsed body on the exception; currently only the
composed message survives. See [Error model](../architecture/error-model.md).

# Citations

[1] [Issue #20, item 5](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20)
[2] `lib/conexa/request.rb:44`, `lib/conexa/errors.rb` — gem v0.1.1.
[3] Documented `{code, message}` examples: [Vendored Postman collection](../api/postman-collection.md) — `CONTRACT_RECURRING_SALE_10`, `CHARGE_06`, `CHARGE_11`.
