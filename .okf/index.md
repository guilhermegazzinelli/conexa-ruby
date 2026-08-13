---
okf_version: "0.1"
---

# conexa-ruby

Knowledge bundle for the `conexa` Ruby gem — a client for the **Conexa API v2**,
the billing/coworking platform (`*.conexa.app`). The gem is a thin, dynamic
wrapper: there are no hand-written attribute definitions, so almost everything a
maintainer needs to know is about *conventions* — how a class name becomes a URL,
how a payload gets camelized, and where those conventions silently disagree with
the published API contract.

Start with [The gem's request pipeline](architecture/request-pipeline.md) if you
are changing behaviour, [Conexa API v2](api/conexa-api-v2.md) if you are checking
the gem against reality, and [Defects](defects/) if you are triaging.

# Areas

* [Architecture](architecture/) - how the gem turns a Ruby call into an HTTP request and back into objects.
* [API](api/) - the upstream Conexa API v2 contract, and the published collection that is its source of truth.
* [Defects](defects/) - confirmed divergences between the gem and the documented API, and the gaps around them.
* [Decisions](decisions/) - choices that shaped the gem, and the ones that are still open.
* [Operations](operations/) - running the suite and cutting a release in this repo.
