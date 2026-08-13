---
type: Component
title: Dynamic object model
description: ConexaObject and Model give every resource its attributes through method_missing — powerful, zero-maintenance, and silent about typos.
tags: [api-contract]
timestamp: 2026-08-13T19:00:00Z
---

# Overview

No resource class in the gem declares its attributes. `ConexaObject` stores a
snake_cased `@attributes` hash and resolves reads and writes through
`method_missing`; `Model` adds persistence (`create`/`save`/`fetch`/`destroy`) and
the URL builders described in [the request pipeline](request-pipeline.md).

This is why adding a field to the API requires **no gem change at all** — and why
the gem cannot tell you when a field disappears.

## Key/casing rules

| Direction | Transform | Where |
|-----------|-----------|-------|
| Response → attributes | `Util.to_snake_case` on every key, recursively | `ConexaObject#update` |
| Attribute read | `Util.to_snake_case(name)` | `method_missing` |
| Request payload | `Util.camelize_hash` | `Request#request_params` |

So `customer.companyId` and `customer.company_id` both work; the camelCase alias
is a compatibility affordance, not a second storage.

## Nested objects are typed by *singularizing the key*

`ConexaObject#update` calls `ConexaObject.convert(value, Util.singularize(key))`,
and `resource_class_for` promotes the result to `Conexa::<Class>` **only if a file
of that name exists** under `lib/conexa/resources/`. Otherwise it stays a plain
`ConexaObject`. Two consequences worth knowing:

- Adding a file to `resources/` retroactively changes the class of nested data
  everywhere it appears — the `RESOURCES` constant is a directory glob evaluated
  at load time.
- `Util.singularize` is a hand-rolled inflector (a 26-rule regex table), not
  ActiveSupport's. A key it singularizes wrongly silently loses its typing.

## `update` merges only what carries attributes

`ConexaObject#update` ignores anything with no attributes to merge — `nil`, `{}`,
and the arrays and scalars [`Request#run`](request-pipeline.md) can also produce.
Two separate release bugs came from not doing this: a documented `204` crashed
every `Model#save`/`#destroy` with `NoMethodError`, and a `200 {}` wiped the whole
object, because `update` deletes every attribute absent from the incoming hash.
That deletion is right for a full refresh and wrong for a write response, so an
empty incoming set is now a no-op rather than a reset.

## The trap: unknown attributes return `nil`, they do not raise

`method_missing` with zero args returns `nil` for any key not in `@attributes`.
A typo (`charge.due_data`) is indistinguishable from a genuinely absent field —
and so is a field that has never existed. That is the whole mechanism behind
[the status predicates defect](../defects/status-predicates-read-fields-that-do-not-exist.md):
`status == "active"` on a resource with no `status` reads as `nil == "active"`,
quietly false, forever.
`respond_to_missing?` is implemented, so `respond_to?` is honest — but nothing in
normal call syntax consults it. When a value reads as `nil` unexpectedly, check
`obj.attributes.keys` before assuming the API omitted it.

## `blank?`/`present?` are conditionally defined

`lib/conexa/core_ext.rb` defines them on `Object` **only if not already defined**,
so the gem coexists with ActiveSupport instead of fighting it. The gem's internals
(`Model#destroy`, `TokenManager`) depend on them being present either way.

# Citations

[1] `lib/conexa/object.rb`, `lib/conexa/model.rb`, `lib/conexa/util.rb`, `lib/conexa/core_ext.rb` — gem v0.1.1.
