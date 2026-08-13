---
type: Reference
title: Vendored Postman collection
description: docs/postman-collection.json is the only complete source for request bodies, required flags and error codes — and the thing every gem claim should be checked against.
resource: file://docs/postman-collection.json
tags: [api-contract, testing]
timestamp: 2026-08-13T16:00:00Z
---

# Overview

`docs/postman-collection.json` (~1.8 MB) is a vendored copy of Conexa's published
Postman collection. It documents **83 operations** with field tables,
required/optional flags, conditional-requirement prose and example error
responses — none of which appear anywhere else.

It is the reference of record for this repo, and when the gem and the collection
disagree about a **verb or a path** the collection has been right every time
(see [Defects](../defects/)).

**It is not authoritative about response fields.** It under-documents them: the
live API returns `isActive` on `GET /contract/:id`, and no export of the
collection — including the 2026-08-13 refresh — shows it. A payload-level check
built on the collection has to be "every field the gem models appears in *some*
documented response", never "this response has exactly these fields", or it will
report a field that exists as missing.

# Refreshing it

Two routes, and they are **not** equivalent.

**Preferred — export from Postman.** Open the collection in the app or on the
web and export as *Collection v2.1*, then replace the file. This is what the
vendored copy is: `url` as a Hash with a `path` array, and descriptions in
Markdown.

**Fallback — the documenter API**, when you cannot reach the app:

```bash
curl -s 'https://documenter.gw.postman.com/api/collections/25182821/2s93RZMpcB?segregateAuth=true&versionTag=latest' \
  > docs/postman-collection.json
```

Same 83 operations and 348 response examples, but it renders descriptions to
**HTML** — the `POST /contract` field table goes from 55 lines of Markdown to 321
lines of `<table>`/`<td>`, same content, far worse to read or grep — and it emits
`url` as a plain String. Both shapes are handled, but prefer the export.

After refreshing, re-run `spec/contract/api_contract_spec.rb` and prune the
`UNDOCUMENTED` allowlist — the 2026-08-13 refresh documented five paths that had
been allowlisted as unverified, and leaving them there weakens the check. Then
regenerate the [resource catalogue](../architecture/resource-catalog.md).

The refresh is additive so far: 68 operations became 83, none removed. New in
2026-08: `/extraFields` (CRUD), `/potentialCustomer`, `POST`/`PATCH`/`DELETE` on
`/product`, `POST /contract/:id/signature/request`, and the reads for
`/accounts`, `/suppliers` and `/serviceCategories` that a live probe had already
confirmed existed.

# Reading it programmatically

Items are nested arbitrarily deep under `item[]`; leaves are the ones carrying a
`request` key.

**`url` has two shapes across exports.** The 2026-02 export used a Hash with a
`path` array; the 2026-08 refresh uses a plain String with the full URL
(`https://YOUR_SUBDOMAIN.conexa.app/index.php/api/v2/auth`). Anything reading the
collection has to normalise both, or a refresh silently changes what it compares.
`spec/support/postman_collection.rb#path_of` handles it, and `operations` raises
when it ends up with nothing rather than letting the contract spec pass over an
empty set.

A minimal walker:

```ruby
def walk(items, &b)
  Array(items).each { |i| i["item"] ? walk(i["item"], &b) : b.call(i) }
end

walk(JSON.parse(File.read("docs/postman-collection.json"))["item"]) do |leaf|
  r = leaf["request"] or next
  url = r["url"]
  path = url.is_a?(Hash) ? "/" + Array(url["path"]).join("/") : url.to_s
  puts "#{r['method']} #{path.split('?').first}"
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
