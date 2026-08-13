---
type: Defect
title: Company.all requested /companys, which is undocumented but works
description: The naive pluralizer emits /companys where the collection documents /companies — the live API happens to route both, so this was an inconsistency rather than the breakage it was first reported as.
status: resolved
tags: [http, api-contract, testing]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0**, and **downgraded**. `Company` overrides `url`/`show_url` to `/companies` and `/company`, and the unit spec that asserted `/companys` now asserts the documented path.
>
> But the original claim here — that `Company.all` could not work against a live tenant — was **wrong**, and it was wrong because it was inferred from the collection instead of tested. Probing the production tenant on 2026-08-12 showed the API routes **both** spellings.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

`Model.url` pluralizes by appending `"s"` to the class name
([request pipeline, stage 2](../architecture/request-pipeline.md)). For
`Company` that yields:

```ruby
Conexa::Company.url   # => "/companys"
```

The collection documents `GET /companies`, so this looked like a guaranteed 404.
It is not. Verified against the live tenant, 2026-08-12:

```
GET /companies?limit=1  -> 200, {data, pagination}
GET /companys?limit=1   -> 200, identical
```

The API is not merely permissive — `/companyzzz` and `/naoExiste` both 404 — so
`/companys` is a real route, presumably a lenient alias. What the gem had was an
undocumented path that happens to work, not a broken one.

The override still stands: matching the documented path is the right default, and
an alias nobody documents can disappear without notice. But the severity was
overstated, and the lesson is the one this whole release is about — a claim
derived from a document is a hypothesis until something answers it.

Resources with irregular plurals are expected to override `url`/`show_url` —
`RoomBooking`, `Account`, `ServiceCategory` and `RecurringSale` all do.
`Company` does not.

# The spec locks the bug in

This is the sharpest instance of the pattern in
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md),
because here the wrong value is not merely stubbed — it is **asserted**:

```ruby
# spec/conexa/resources/company_spec.rb:9
it 'returns companies endpoint' do
  expect(described_class.url).to eq('/companys')
end
```

`spec/integration/company_spec.rb:50` then stubs `/companys` to match. The test
name says "companies"; the assertion says `/companys`. Fixing the code will fail
both specs, which is the correct outcome — update them, do not accommodate them.

# Suggested fix

```ruby
class Company < Model
  class << self
    def url(*params)      = ["/companies", *params].join('/')
    def show_url(*params) = ["/company", *params].join('/')
  end
end
```

Then re-run the [resource catalogue](../architecture/resource-catalog.md) sweep;
it is the check that found this and is the cheapest way to confirm nothing else
in the same family is left.

# Citations

[1] `lib/conexa/resources/company.rb`, `lib/conexa/model.rb` (`url`) — gem v0.1.1.
[2] [Vendored Postman collection](../api/postman-collection.md) — *Company > /companies*.
[3] Confirmed 2026-08-11 by diffing every `Model` subclass's emitted URL against the collection.
