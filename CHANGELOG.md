# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-08-11

Aligns the gem with the published API v2 contract. **0.1.1 is broken**:
`Charge.settle` and `Contract.end_contract` 404 against a live tenant, and a
successful write that answers with an empty body raises `NoMethodError` after
the operation has already taken effect — in a billing integration that invites a
retry. Upgrading is strongly recommended.

Every fix below was verified against `docs/postman-collection.json`, Conexa's own
published documentation, and is now enforced by
`spec/contract/api_contract_spec.rb`.

### Fixed
- **Empty response bodies no longer raise.** `Request#run` returns `{}` for an
  empty, whitespace or `null` body at any status. With the Oj adapter
  `MultiJson.decode("")` returns `nil` without raising, so the previous
  `rescue MultiJson::ParseError` / `204` guard never fired — even a documented
  `204` success (`PATCH /charge/settle/:id`) raised `NoMethodError`, which is not
  a `Conexa::ConexaError` and escaped `rescue Conexa::ConexaError`.
- **Action endpoints use the documented verb.** `Charge#settle`,
  `Contract#end_contract` and `RecurringSale#end_recurring_sale` send `PATCH`;
  `POST` 404s.
- **`Conexa::Company.all` requests `/companies`.** `Model#url` pluralizes by
  appending `"s"`, which produced `/companys`.
- **Nested arrays are camelized.** `Util.camelize_hash` treated an `Array` as a
  scalar, so snake_case keys inside arrays of objects were sent untouched and
  rejected. Affects `complementaryServices`, `productQuotas`, `devices`,
  `extraFields`, `bookingModels`, `visitors` and `costCenters` — ten documented
  endpoints across seven resources.
- **`page`/`size` are converted to `limit`/`offset`** instead of being sent. The
  API validates `page` and then ignores it, always answering `offset: 0`, so a
  loop driven by `hasNext` never terminated and silently re-yielded the same
  batch. Non-positive or non-integer values now raise `Conexa::RequestError`.
- **`Model#id` falls back to `attributes["id"]` again.** `primary_key_attribute`
  aliased `#id` onto the resource key, making the documented fallback dead code —
  write endpoints answer with `{"id": N}`, which is what `Model#create` reads.
- **`ResponseError` no longer raises `NoMethodError` on malformed bodies.** It was
  handed a `RestClient::Response`, which has no `#message`.
- `README.md` configured a non-existent `config.subdomain`; the quick start now
  runs.
- `lib/conexa/resources/supplier.rb` shipped as `0600`, breaking `require` on a
  shared install.

### Added
- **Read-only mode.** `config.read_only = true`, `CONEXA_READ_ONLY=1`, or a
  thread-local `Conexa.read_only { ... }` block. Any non-`GET` request raises
  `Conexa::ReadOnlyError` before it leaves the process; authentication stays
  allowed. Settling a charge moves money and can issue an NF-e, so this is a
  guard worth having when you only mean to read.
- **`ResponseError#api_errors`, `#api_error_codes`, `#api_error_messages`,
  `#api_response`** — normalise the API's two error shapes (`{field, messages}`
  and `{code, message}`). Consumers that only handled the first rendered
  business-rule errors as blank strings, which is how
  `CONTRACT_RECURRING_SALE_10` stayed invisible through eight attempts.
  `api_error_codes` makes documented codes such as `CHARGE_11` usable as control
  flow — the way to tell an already-settled charge from a real failure.
- **`Contract#set_end_date`** (with `end_contract` kept as an alias), taking the
  documented `date:`, `reason_id:` and `unlink_customer:`. The endpoint both
  closes a contract and amends its end date, and a future date on a closed
  contract reopens it.
- **Contract-level test coverage**: `spec/contract/api_contract_spec.rb` checks
  every emitted URL and action verb against the vendored collection, with an
  explicit allowlist and a guard that fails when an endpoint is added without one.
  `spec/support/request_capture.rb` asserts the request the gem actually emits
  rather than stubbing the expected one.
- `verify_partial_doubles = true`.
- YARD documentation of `POST /contract`'s fields, including the conditional
  `due_day` rule and the atomic `firstOccurrenceSettleRetroactive` flow.
- `claude_scripts/multi_ruby_specs/` runs the suite across Ruby 3.1–3.4 locally.

### Changed
- **Breaking**: `end_contract` sends the documented `date`; `end_date:` still
  works as a deprecated alias and will be removed in 0.3.0.
- **Breaking**: writes that answer with an empty body now return normally instead
  of raising. Callers treating the exception as a signal must be reviewed.
- **Breaking**: `page`/`size` no longer reach the wire.
- Minimum Ruby is now **3.1** (was 2.6, never tested below 3.1). CI covers
  3.1–3.4.
- `rest-client` and `multi_json` are version-bounded. `multi_json`'s adapter
  behaviour is load-bearing — the empty-body defect exists because Oj returns
  `nil` rather than raising.
- The gemspec's development dependencies move to bundler's `:test` group, and
  `debug`/`byebug` to an optional `:development` group, so a native-extension
  failure in `io-console` can no longer stop `bundle exec rspec`.
- **The packaged gem is 48 KB, down from 163 KB.** `spec.files` shipped the whole
  repository — including `docs/postman-collection.json` (1.7 MB) — against 58 KB
  of library code. It now ships `lib/` and the documentation only.
- **`Gemfile.lock` is no longer committed**, as is conventional for a gem: a
  pinned lockfile defeats testing against the range the gemspec allows, and CI
  had been working around it by deleting the file before `bundle install`.
- **`rake` passes again.** The default task is `spec` + `rubocop`, and RuboCop's
  ~2000 pre-existing offences made it fail, which is why CI ran lint with
  `continue-on-error`. A generated `.rubocop_todo.yml` grandfathers them, so new
  code is genuinely linted and CI can gate on it.
- `rake spec:all` runs the suite across every supported Ruby via mise, replacing
  an ad-hoc shell script; `rake ci` mirrors the CI pipeline. CI uses
  `bundler-cache: true`.

### Removed
- **Breaking**: `Conexa::Client`, `Conexa::Authenticator`, `Conexa::TokenManager`
  and `Conexa::OrderCommon`. They referenced five `Conexa` module methods that
  never existed, so any real use raised `NoMethodError`; their specs passed only
  because they stubbed those methods into being. The `jwt` dependency goes with
  them — `Conexa::Auth` (the v2 `/auth` resource) is unaffected.

### Security
- A live Bearer token for a production tenant was committed in
  `spec/spec_helper.rb`, and `spec/cassettes/customer.yml` was recorded against
  that tenant with ~120 real customers (names, CNPJ/CPF, emails, phones,
  addresses). Both are removed and the cassette anonymised;
  `claude_scripts/sanitize_cassettes/` holds the sanitiser and VCR now filters
  the token from new recordings. **The exposed token must be rotated in Conexa.**

## [0.1.1] - 2026-03-31

### Added
- Instance methods `Customer#persons`, `Customer#contracts`, `Customer#charges` for idiomatic Ruby usage
  - `customer = Conexa::Customer.find(127); customer.persons` — fetches persons for the loaded customer
- Class methods `Customer.persons(id)`, `Customer.contracts(id)`, `Customer.charges(id)` remain available
  - Useful to save a request when you don't need the customer data itself

### Changed
- Customer sub-resource methods now available in both class and instance forms

## [0.1.0] - 2026-03-31

### Added
- `Result#next_page` — automatically fetches the next page preserving original filter params
- `Result#has_next?` — convenience method to check if more pages are available
- Pagination migration guide added to README (EN/PT-BR) and REFERENCE.md
- Validation for `limit` (must be positive integer) and `offset` (must be non-negative integer) parameters
- `frozen_string_literal: true` pragma added to all Ruby source files
- ActiveSupport compatibility guard for `blank?`/`present?` monkey-patches
- `respond_to_missing?` implemented in `ConexaObject` and `Result` (Ruby best practice)
- Integration tests for all new API v2 resources (24 specs)
- Unit tests for pagination validation and `class_name` camelCase preservation (6 specs)
- Total: 502 specs

### Changed
- **Breaking**: Default pagination is now `limit: 100, offset: 0` (was `page: 1, size: 100`)
  - Calling `.all` or `.find_by` without pagination params now uses the new model
  - Legacy `page`/`size` is only used when explicitly passed (emits deprecation warning)
- `Model.all` simplified — delegates directly to `find_by` without double param extraction
- `Model.class_name` now returns proper lowerCamelCase (e.g. `recurringSale` instead of `recurringsale`)
- `OrderCommom` renamed to `OrderCommon` (backwards-compatible alias kept)
- `Bill#save` now raises `NoMethodError` with descriptive message
- README updated: all examples now use correct method names (`.all`, `.find`, `.destroy`)
- README error handling section rewritten with actual exception classes

### Fixed
- **Concurrency bug**: `DEFAULT_HEADERS` constant was mutated on every request; now uses `.dup`
- **Boolean false bug**: `Result#method_missing` skipped `false` attribute values due to `||` operator
- **ValidationError crash**: undefined variable `error` in block scope — fixed to use `msg`
- **TokenManager typo**: `ShiConexa` → `Conexa` in credentials handling
- **Singularize**: `SINGULARS` patterns were stored as strings, never used as regex — rewritten with proper `Regexp` objects
- **Deep copy**: `Result#next_page` now uses `Marshal.load(Marshal.dump(...))` to prevent param mutation between pages
- Stray `-` character removed from `util.rb`
- Removed dead code: `Hash#except_nested` monkey-patch, commented-out `to_s` method

## [0.0.9] - 2026-03-30

### Added
- **New pagination model**: `limit`/`offset`/`hasNext` — more efficient, avoids calculating total records
  - Pass `limit:` to any `.all` or `.find_by` to use the new pagination
  - Old `page`/`size` pagination emits deprecation warning (deadline: 2026-08-01)
- **New resources:**
  - `Conexa::ReceivingMethod` — Meios de Recebimento (`/receivingMethods`, `/receivingMethod/:id`)
  - `Conexa::PaymentMethod` — Meios de Pagamento (`/paymentMethods`, `/paymentMethod/:id`)
  - `Conexa::BillCategory` — Categorias de Despesa (`/billCategories`, `/billCategory/:id`)
  - `Conexa::BillSubcategory` — Subcategorias de Despesa (`/billSubcategories`, `/billSubcategory/:id`)
  - `Conexa::CostCenter` — Centros de Custo (`/costCenters`, `/costCenter/:id`)
  - `Conexa::Account` — Contas Bancárias (`/accounts`, `/account/:id`)
  - `Conexa::ServiceCategory` — Categorias de Serviço (`/serviceCategories`, `/serviceCategory/:id`)
  - `Conexa::RoomBooking` — Reservas de Sala (`/room/bookings`, `/room/booking`) with cancel, checkout, checkin
- `Product` now supports full CRUD (POST `/product`, DELETE `/product/:id`) per API v2 update

### Changed
- `Model#extract_page_size_or_params` rewritten to support dual pagination modes
- `Customer.persons`, `Customer.contracts`, `Customer.charges` migrated to `limit: 100`

### Fixed
- `Supplier` list URL corrected from `/supplier` to `/suppliers`
- `Supplier` now has `primary_key_attribute :supplier_id`
- `Product` now has `primary_key_attribute :product_id`

## [0.0.8] - 2026-02-19

### Fixed
- `Auth.login` usava `Request.post` (inclui header Authorization) ao invés de `Request.auth`
- `Model#primary_key_name` retornava nomes incorretos para classes compostas (ex: `creditcard_id` ao invés de `credit_card_id`)
- `Model.destroy(id)` falhava para resources com `primary_key_attribute` definido
- `Model#destroy` retornava Hash interno ao invés de `self`
- `Person` tinha `find`, `all` e `find_by` desnecessariamente desabilitados (a API suporta todos os endpoints CRUD)

### Added
- Testes de autenticação com cassettes VCR (13 specs)
- Testes de integração WebMock para Sale, RecurringSale, Plan, Product, Bill, Supplier, Company, CreditCard, Person e InvoicingMethod
- Total de testes: 407 specs

### Changed
- `REFERENCE.md` reescrito com documentação completa de todos os endpoints baseada na collection Postman
- nokogiri atualizado para 1.19.1

## [0.0.7] - 2026-02-12

### Added
- REFERENCE.md - Complete API reference optimized for LLMs/AI agents
- Comprehensive test suite (330+ specs)
- `Model.primary_key_attribute` DSL for cleaner resource definitions
- YARD documentation for all resource attributes (`@!attribute` directives)
- Documentation for `method_missing` behavior in ConexaObject

### Changed
- **Convention**: Use `snake_case` for all Ruby code (gem auto-converts to camelCase for API)
- README updated with snake_case examples and "Convention" section
- Resource methods now use snake_case with camelCase aliases for backwards compatibility
  - `customer.customer_id` (primary) / `customer.customerId` (alias)
- Simplified resources using `method_missing` for attribute access (-280 lines)

### Fixed
- Resource attribute methods now correctly access snake_case keys in `@attributes`
- Compound-named models (RecurringSale, CreditCard, InvoicingMethod) now have correct primary keys
- Array attributes (`phones`, `emails_message`, etc.) return `[]` instead of `nil` when empty

## [0.0.6] - 2026-02-11

### Fixed
- `Result#empty?` now correctly delegates to data array
- `Util.camelize_hash` guards against nil values

## [0.0.5] - 2026-01-15

### Added
- Initial release with core resources
- Customer, Contract, Sale, Charge, Bill resources
- RecurringSale with end functionality
- Charge with settle and PIX methods
- Pagination support

[Unreleased]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.9...v0.1.0
[0.0.9]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.8...v0.0.9
[0.0.8]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.7...v0.0.8
[0.0.7]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/guilhermegazzinelli/conexa-ruby/releases/tag/v0.0.5
