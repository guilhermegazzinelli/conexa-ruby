# Defects

Nine divergences between the gem and the documented API, found by verifying
[issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20) against
`docs/postman-collection.json` and by sweeping the gem against it.

**All nine are fixed in 0.2.0.** The concepts are kept rather than deleted: each
explains why a piece of code or a spec looks the way it does, and what to watch
for if the area is touched again. `spec/contract/api_contract_spec.rb` now fails
CI on a recurrence of the URL and verb families.

# Were silent or costly

* [Empty response body raises NoMethodError after a successful write](empty-body-nomethoderror.md) - a completed settlement reported as a crash, inviting a double-charge.
* [Wrong HTTP verb on action endpoints](wrong-verb-on-action-endpoints.md) - three methods POSTed where the API documents PATCH, and `end_contract` sent the wrong field name.
* [Nested arrays were not camelized](nested-array-not-camelized.md) - snake_case keys inside arrays of objects were rejected across ten endpoints.
* [page is accepted by the API and silently ignored](page-param-silently-ignored.md) - the legacy pagination path returned the first page forever and looked like real data.

# Were broken but loud

* [Company.all requests /companys](wrong-url-for-company-list.md) - the naive pluralizer, with a unit spec asserting the wrong URL as correct.
* [The English README quick-start does not run](readme-quickstart-uses-nonexistent-subdomain.md) - `config.subdomain` never existed.
* [Dead legacy TokenManager ships in the gem](dead-legacy-token-manager.md) - four unreachable classes whose specs stubbed the missing interface into existence.

# Were gaps rather than breakage

* [Contract creation fields are not modelled](contract-creation-fields-gap.md) - including a conditionally-forbidden `dueDay` and an atomic create-and-settle option.
* [Error shapes are not normalised for consumers](error-shape-normalisation-gap.md) - business-rule errors reached consumers as blank strings.
