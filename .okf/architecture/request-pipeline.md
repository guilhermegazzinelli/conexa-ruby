---
type: Component
title: The gem's request pipeline
description: How a call on a resource class becomes an HTTP request and comes back as a typed object — the four conventions that decide verb, URL, payload casing and return shape.
tags: [http, api-contract]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

Every call in the gem flows through the same four stages. Nothing is declared
per-resource; each stage is a **convention derived from the class name**, which is
why a resource can be wrong against the API without any file looking wrong.

```
Conexa::Charge.settle(555)
  └─ Model.find(555)        → GET  /charge/555            (2) URL from class name
  └─ Charge#settle          → POST /charge/settle/555     (1) verb chosen at the call site
       └─ Request#run       → payload camelized           (3) Util.camelize_hash
            └─ Request#call → ConexaObject.convert        (4) typed by resource name
```

## 1. Verb — chosen at the call site, not derived

`Model` fixes the verb for the CRUD five: `create` → POST, `save` → PATCH,
`find` → GET, `destroy` → DELETE. Every **action** endpoint (`settle`, `end`,
`cancel`, `checkout`) picks its own verb by hand in the resource file. There is
no check that the choice matches the API — which is exactly how
[wrong HTTP verb on action endpoints](../defects/wrong-verb-on-action-endpoints.md)
happened three times over.

## 2. URL — derived from the class name

`Model.class_name` lower-cases the first letter of the demodulized class name, and:

| Builder | Formula | `Charge` | `RecurringSale` |
|---------|---------|----------|-----------------|
| `url` | `/<className>s` | `/charges` | `/recurringSales` |
| `show_url(*p)` | `/<className>/<p…>` | `/charge/555` | `/recurringSale/1` |

The pluralizer is a bare `+ "s"`. Any resource whose English plural is irregular
**must** override `url`/`show_url` — several do (`RoomBooking` → `/room/bookings`,
`Account`, `ServiceCategory`, `RecurringSale`). `Company` does not, and that is
[Company.all requests /companys](../defects/wrong-url-for-company-list.md).

## 3. Payload — camelized on the way out, snake_cased on the way in

`Request#request_params` runs every outbound param hash through
`Util.camelize_hash` (recursively), so Ruby-idiomatic `end_date:` leaves as
`endDate`. The gem never validates the resulting key against the endpoint's
documented body, so a **wrong field name is indistinguishable from a right one**
until the API answers 400. See
[Contract lifecycle](../api/contract-lifecycle.md) for the case where this cost
real money.

Note the asymmetry: for `GET`, params are placed in `headers[:params]` (RestClient's
query-string channel) rather than a body.

## 4. Return shape — paginated or not

`Request#call` branches on whether the decoded response carried a `pagination`
key. With it, you get a [`Result`](pagination.md); without it, a single typed
object or an array of them, resolved by
[the dynamic object model](object-model.md).

# Failure surface

`Request#run` is a single method holding the whole error taxonomy — see
[Error model](error-model.md). Its success path is one line
(`response.dig("data") || response`) and it assumes the body decodes to a Hash,
which is the root of
[empty response body raises NoMethodError](../defects/empty-body-nomethoderror.md).

# Citations

[1] `lib/conexa/request.rb`, `lib/conexa/model.rb` — gem v0.1.1.
[2] [Conexa API v2 published collection](../api/postman-collection.md)
