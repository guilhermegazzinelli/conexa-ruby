# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.7...HEAD
[0.0.7]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/guilhermegazzinelli/conexa-ruby/releases/tag/v0.0.5
