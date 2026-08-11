---
type: Defect
title: Company.all requests /companys
description: The naive class-name pluralizer emits /companys where the API documents /companies — and a unit spec asserts the wrong URL as correct.
status: resolved
tags: [http, api-contract, testing]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** `Company` overrides `url`/`show_url` to `/companies` and `/company`. The unit spec that asserted `/companys` now asserts the documented path.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

`Model.url` pluralizes by appending `"s"` to the class name
([request pipeline, stage 2](../architecture/request-pipeline.md)). For
`Company` that yields:

```ruby
Conexa::Company.url   # => "/companys"
```

The API documents `GET /companies`. `Conexa::Company.all` cannot work against a
live tenant.

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
