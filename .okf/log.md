# Update Log

## 2026-08-11

### v0.2.0 — the fixes
* **Update**: all nine defects fixed and released as v0.2.0. Each concept in [Defects](defects/) is kept and marked resolved — they explain why the code and specs look as they do — and [the defects index](defects/index.md) now reads as history rather than a backlog.
* **Creation**: [Nested arrays were not camelized](defects/nested-array-not-camelized.md) — a tenth defect, found while planning the release and absent from issue #20: `Util.camelize_hash` treated an Array as a scalar, so snake_case keys inside arrays of objects were rejected across ten endpoints in seven resources.
* **Creation**: [Read-only mode](architecture/read-only-mode.md) — `config.read_only`, `CONEXA_READ_ONLY`, and a thread-local `Conexa.read_only { }` block, guarding at `Request#run`. Motivated by the double-settlement incident: a read-only client turns that class of mistake into an immediate exception.
* **Update**: [the resource catalogue](architecture/resource-catalog.md) regenerated against v0.2.0 — `Company` now emits `/companies`, `OrderCommon` is gone, and the sweep runs in CI as `spec/contract/api_contract_spec.rb` instead of by hand.
* **Update**: [stubbed specs hide contract drift](decisions/stubbed-specs-hide-contract-drift.md) resolved — all three steps shipped (request-capture helper, collection-driven contract spec, `verify_partial_doubles`).
* **Update**: [the pagination migration](decisions/pagination-migration.md) closed by converting `page`/`size` to `limit`/`offset` rather than removing or raising, so legacy callers are fixed instead of broken.
* **Update**: [Error model](architecture/error-model.md) and [Authentication](architecture/authentication.md) reflect `ResponseError`'s new accessors, `ReadOnlyError`, and the removal of the JWT path.
* **Update**: [Running the suite](operations/running-the-suite.md) — the io-console blocker is fixed structurally rather than worked around, and the multi-Ruby runner is documented.
* **Update**: VCR cassettes recorded against a real tenant were anonymised and `spec_helper.rb` now filters the API token out of new recordings — see `claude_scripts/sanitize_cassettes/`.

### Bundle creation
* **Creation**: bundle seeded while verifying [issue #20](https://github.com/guilhermegazzinelli/conexa-ruby/issues/20) against gem v0.1.1 and `docs/postman-collection.json`. 20 concepts across five areas.
* **Creation**: [Architecture](architecture/) — the four conventions of [the request pipeline](architecture/request-pipeline.md), [the dynamic object model](architecture/object-model.md), [pagination](architecture/pagination.md), [the error model](architecture/error-model.md), [authentication](architecture/authentication.md), and the generated [resource catalogue](architecture/resource-catalog.md).
* **Creation**: [API](api/) — [Conexa API v2](api/conexa-api-v2.md), the [vendored collection](api/postman-collection.md) as source of truth, and the two operations with non-obvious semantics: [contract create/end](api/contract-lifecycle.md) and [charge settlement](api/charge-settlement.md).
* **Creation**: [Defects](defects/) — all six items of issue #20 confirmed, plus three found by sweeping the gem against the collection: [`Charge#settle` and `RecurringSale#end_recurring_sale` share the wrong-verb defect](defects/wrong-verb-on-action-endpoints.md), [`Company.all` requests `/companys`](defects/wrong-url-for-company-list.md), and [the README quick-start does not run](defects/readme-quickstart-uses-nonexistent-subdomain.md). Also recorded [the dead legacy TokenManager](defects/dead-legacy-token-manager.md).
* **Update**: issue #20's defect 3 amplified — with the Oj adapter an empty body decodes to `nil` without raising, so [the `204` guard in `request.rb:53` is unreachable](defects/empty-body-nomethoderror.md) and even a documented `204` success raises.
* **Update**: issue #20's item 5 narrowed — the gem's own exception *does* surface `{code, message}` errors readably; [the gap is the missing structured accessor](defects/error-shape-normalisation-gap.md), not data loss.
* **Creation**: [Decisions](decisions/) — [the limit/offset migration](decisions/pagination-migration.md) and its expired deprecation window, and [why 502 green specs hide seven defects](decisions/stubbed-specs-hide-contract-drift.md).
* **Creation**: [Operations](operations/) — [running the suite](operations/running-the-suite.md) around the `io-console` build failure, and [cutting a release](operations/release-process.md).
