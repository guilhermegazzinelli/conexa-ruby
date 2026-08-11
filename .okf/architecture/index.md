# Architecture

How the gem turns a Ruby call into an HTTP request and back into objects. Almost
nothing here is declared per-resource — it is all convention, which is what makes
the gem small and what makes its bugs invisible.

* [The gem's request pipeline](request-pipeline.md) - the four stages that decide verb, URL, payload casing and return shape.
* [Dynamic object model](object-model.md) - ConexaObject and Model give every resource its attributes through method_missing.
* [Resource catalogue — gem classes vs documented endpoints](resource-catalog.md) - the audit table comparing every emitted URL against the published collection.
* [Pagination and the Result object](pagination.md) - limit/offset versus the deprecated page/size, and how to walk pages.
* [Error model](error-model.md) - the exception taxonomy, and the API's two error shapes.
* [Authentication and configuration](authentication.md) - the Bearer-token path, and the JWT one that was removed in 0.2.0.
* [Read-only mode](read-only-mode.md) - the guard that refuses every non-GET request, and why a billing client needs one.
