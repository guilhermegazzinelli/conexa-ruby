---
type: Reference
title: Vendored Postman collection
description: docs/postman-collection.json is the only complete source for request bodies, required flags and error codes — and the thing every gem claim should be checked against.
resource: file://docs/postman-collection.json
tags: [api-contract, testing]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

`docs/postman-collection.json` (~1.7 MB) is a vendored copy of Conexa's published
Postman collection. It documents **68 operations** with field tables,
required/optional flags, conditional-requirement prose and example error
responses — none of which appear anywhere else.

It is the reference of record for this repo. When the gem and the collection
disagree, the collection has been right every time so far
(see [Defects](../defects/)).

# Refreshing it

The documenter page is JS-rendered, so `curl` on the human URL returns only a
title. Pull the JSON directly:

```bash
curl -s 'https://documenter.gw.postman.com/api/collections/25182821/2s93RZMpcB?segregateAuth=true&versionTag=latest' \
  > docs/postman-collection.json
```

After refreshing, regenerate the
[resource catalogue](../architecture/resource-catalog.md) — that table is the
diff between the collection and the gem.

# Reading it programmatically

Items are nested arbitrarily deep under `item[]`; leaves are the ones carrying a
`request` key. A minimal walker:

```ruby
def walk(items, &b)
  Array(items).each { |i| i["item"] ? walk(i["item"], &b) : b.call(i) }
end
walk(JSON.parse(File.read("docs/postman-collection.json"))["item"]) do |leaf|
  r = leaf["request"] or next
  puts "#{r['method']} /#{Array(r.dig('url','path')).join('/')}"
end
```

`scripts/extract_fixtures.rb` uses the same shape to turn documented example
responses into `spec/fixtures/*.json` — but note it only descends **two** levels
(`collection['item'] → section['item']`), so it misses anything nested deeper.

Two things the collection is good for that the repo does not yet exploit:
generating request-level contract tests (verb + serialized payload), and lifting
documented error codes such as `CONTRACT_RECURRING_SALE_10` into the gem. Both
are open — see
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md).

# Citations

[1] [Conexa API v2 public documentation](https://documenter.getpostman.com/view/25182821/2s93RZMpcB)
[2] `docs/postman-collection.json`, `scripts/extract_fixtures.rb`.
