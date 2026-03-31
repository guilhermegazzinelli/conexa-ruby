# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.9...v0.1.0
[0.0.9]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.8...v0.0.9
[0.0.8]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.7...v0.0.8
[0.0.7]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/guilhermegazzinelli/conexa-ruby/releases/tag/v0.0.5
