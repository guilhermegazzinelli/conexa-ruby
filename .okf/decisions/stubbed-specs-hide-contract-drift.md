---
type: Decision
title: Stubbed specs hide contract drift
description: 502 examples pass while seven contract defects ship, because the stubs were written from the implementation rather than from the API — the testing strategy needs a second layer.
tags: [testing, api-contract]
timestamp: 2026-08-11T18:40:00Z
---

# Overview

**Resolved in 0.2.0** — all three steps below shipped; this records why they were
necessary and what they cost.

The suite was 502 examples, zero failures, and green with every defect in
[Defects](../defects/) present. That is not a gap in coverage — it is a
consequence of what the specs assert.

Every HTTP interaction is stubbed with WebMock, and each stub was written by
reading the implementation. So:

- `stub_request(:post, …/contract/end/789)` agrees with the wrong verb.
- `expect(Company.url).to eq('/companys')` **asserts** the wrong URL.
- `allow(Conexa).to receive(:secret_key)` conjures a method that does not exist.

A stub written from the code can only ever confirm that the code does what the
code does. Wrong verb, wrong field name, wrong URL and a forbidden field
combination all pass.

# The decision

Keep the stubbed specs — they are fast and they do catch regressions in the
gem's own logic. Add a **second layer** that asserts the wire format against the
API contract rather than against the implementation.

Three concrete steps, cheapest first:

1. **Contract tests on verb and payload.** Instead of stubbing the expected
   request, capture the emitted one and assert on it:

   ```ruby
   sent = nil
   stub_request(:any, /contract\/end/).with { |r| sent = r; true }.to_return(…)
   Conexa::Contract.end_contract(789, date: "2026-07-12")
   expect(sent.method).to eq(:patch)
   expect(JSON.parse(sent.body)).to eq({ "date" => "2026-07-12" })
   ```

   These can be generated straight from
   [the vendored collection](../api/postman-collection.md), which carries the
   documented verb and body for all 68 operations.

2. **A URL sweep in CI.** Diff every `Model` subclass's emitted URL against the
   collection and fail on a mismatch. This is the check that found
   [Company.all requests /companys](../defects/wrong-url-for-company-list.md);
   run once, it is a script, and run in CI it is a guarantee. Its output is the
   [resource catalogue](../architecture/resource-catalog.md).

3. **`verify_partial_doubles = true`.** One line in `spec_helper.rb`. It would
   have failed
   [the TokenManager specs](../defects/dead-legacy-token-manager.md) on the day
   they were written, and it prevents the whole class of "stub a method into
   existence" mistake. Expect it to break existing specs — that is the point.

# Why this matters more than usual here

The gem builds URLs and payloads *by convention* from class names
([request pipeline](../architecture/request-pipeline.md)), so there is no
declaration to review. A wrong endpoint does not look wrong in the diff. The
contract can only be checked against the contract.

# Citations

[1] [Issue #20, "Why the specs don't catch 1, 2 and 4"](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20)
[2] `spec/conexa/resources/company_spec.rb:9`, `spec/integration/contract_spec.rb:116`, `spec/conexa/token_manager_spec.rb:10-15`.
[3] Suite result 502 examples / 0 failures, gem v0.1.1, 2026-08-11.
