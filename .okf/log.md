# Update Log

## 2026-08-13
* **Update**: [Status predicates](defects/status-predicates-read-fields-that-do-not-exist.md) validado contra tenant real antes de publicar. O número que ficou: **44 dos 100 primeiros contratos estão ativos com `end_date` preenchida** — a ressalva do handoff não era caso de canto, e deduzir "encerrado" de `end_date` erraria em quase metade da base.
* **Update**: quatro follow-ups do review da 0.2.1, todos da mesma família — afirmação com mais confiança do que a evidência sustentava. `Charge::STATUSES` era a lista do filtro e não a do campo, montada de uma mensagem de erro truncada no terminal; `REFERENCE.md` ainda ensinava a API removida em sete lugares; deprecations avisavam por chamada; e o próprio check de somente-leitura do handoff não alcançava o guard (#26).
* **Creation**: `Conexa::Deprecation` — avisos uma vez por processo. Um aviso emitido cem vezes deixa de ser lido.
* **Note**: v0.2.1 com tag criada, workflow parado aguardando aprovação. Issues #23 e #26 fechadas.
* **Creation**: [Status predicates read fields the API never sends](defects/status-predicates-read-fields-that-do-not-exist.md) — issue #23, corrigido na 0.2.1. `Contract#active?` comparava um `status` que contrato nunca teve, e `Charge#pending?`/`#overdue?` comparavam valores que a API rejeita. Os três respondiam `false` sempre, e o primeiro empurrava o chamador a criar contrato duplicado.
* **Update**: a camada de contrato passou a checar **atributos**, não só verbo e caminho — `PostmanCollection.response_fields`. Era a lacuna que deixou um predicado ler campo inexistente atravessar quatro rodadas de review e uma release.
* **Update**: [collection atualizada](api/postman-collection.md) — 68 para 83 operações, e as duas rotas de refresh documentadas como não equivalentes (o export nativo traz Markdown e `url` como Hash; o documenter renderiza HTML).
* **Note**: a lacuna de documentação do `isActive` foi reportada ao time do Conexa.
* **Creation**: [Validating against the live API](operations/validating-against-the-api.md) — o runbook que faltava. Sem tenant de teste, toda afirmação sobre a API ou é verificada contra produção em modo leitura, ou é hipótese; este projeto já publicou hipótese como fato duas vezes. Documenta a sonda, os endpoints que nunca são tocados, e como as três formas de 404 da API distinguem rota, ação e permissão.
* **Creation**: `docs/HANDOFF-0.2.1.md` — guia para o cliente validar a 0.2.1 a partir do repositório antes de publicar, começando com o modo somente-leitura ligado.

## 2026-08-13
* **Update**: **v0.2.0 publicada no RubyGems.** PR #21 mergeado (14 commits, 97 arquivos), issues #20, #11 e #12 fechadas. Publicada via [Trusted Publishing](operations/release-process.md) — nenhuma chave de API existe nesta máquina nem nos secrets do repositório.
* **Update**: [Cutting a release](operations/release-process.md) deixou de ser teórico. O caminho completo rodou: `workflow_call` reusando o gate do PR, os dois gates novos (tag == `Conexa::VERSION`, conteúdo do pacote), aprovação obrigatória no environment `release`, e a troca OIDC → publicação.
* **Update**: a tag `v0.1.1` foi reapontada de `fa815df` (que carregava `VERSION = "0.1.0"`) para `a7fdc6d`, cujo `lib/` é byte-idêntico ao gem publicado — verificado baixando o `.gem` do RubyGems e comparando. As oito tags do repositório agora batem com a versão do código que apontam.
* **Note**: duas armadilhas custaram uma tentativa cada no primeiro release. O gem chama-se `conexa`, o repositório `conexa-ruby` — registrar o trusted publisher pelo nome do repositório autentica mas não autoriza (`You are not allowed to push this gem`). E o fluxo de *pending* trusted publisher serve para reservar nome de gem inexistente, não para um já publicado.

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
