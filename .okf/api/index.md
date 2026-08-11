# API

The upstream contract the gem is supposed to honour, and the document that
defines it. When the gem and this area disagree, this area has been right every
time.

* [Conexa API v2](conexa-api-v2.md) - the service: subdomain, Bearer token, envelope and casing conventions.
* [Vendored Postman collection](postman-collection.md) - `docs/postman-collection.json`, the only complete field-level reference, and how to refresh it.

# Operations with non-obvious semantics

* [Contract create and end](contract-lifecycle.md) - the conditional `dueDay` rule, atomic create-and-settle, and the "end" endpoint that also amends and reopens.
* [Charge settlement](charge-settlement.md) - a money-moving write whose documented success response is an empty `204`.
