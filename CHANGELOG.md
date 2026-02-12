# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.7] - 2026-02-12

### Added
- REFERENCE.md - Complete API reference optimized for LLMs/AI agents
- Comprehensive test suite (330+ specs)
- snake_case conversion tests
- Auth resource for username/password authentication
- YARD documentation for main resources
- Helper methods: `billed?`, `paid?`, `editable?`, `active?`, `ended?`
- Customer convenience methods: `persons`, `contracts`, `charges`
- Charge methods: `cancel`, `send_email`, `pix`

### Fixed
- **Breaking**: Resource attribute methods now use snake_case internally (#14)
  - `charge.charge_id` instead of `charge.chargeId`
  - `customer.customer_id` instead of `customer.customerId`
  - camelCase aliases maintained for backwards compatibility
- Renamed `Addres` to `Address` (typo fix)
- VCR configuration for integration tests

### Changed
- README updated to use snake_case convention throughout
- Added "Convention" section explaining automatic camelCase ↔ snake_case conversion
- Improved documentation across all resources

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
