# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README with usage examples for all resources
- Auth resource for username/password authentication
- Spec fixtures extracted from official Postman collection
- YARD documentation for main resources (Customer, Sale, Charge, Contract)
- Helper methods: `billed?`, `paid?`, `editable?`, `active?`, `ended?`
- Customer convenience methods: `persons`, `contracts`, `charges`
- Charge methods: `cancel`, `send_email`, `pix`

### Fixed
- Renamed `Addres` to `Address` (typo fix)

### Changed
- Improved documentation across all resources

## [0.0.6] - 2024-02-11

### Fixed
- `Result#empty?` now correctly delegates to data array
- `Util.camelize_hash` guards against nil values

## [0.0.5] - 2024-01-15

### Added
- Initial release with core resources
- Customer, Contract, Sale, Charge, Bill resources
- RecurringSale with end functionality
- Charge with settle and PIX methods
- Pagination support

[Unreleased]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.6...HEAD
[0.0.6]: https://github.com/guilhermegazzinelli/conexa-ruby/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/guilhermegazzinelli/conexa-ruby/releases/tag/v0.0.5
