---
type: Defect
title: The English README quick-start does not run
description: README.md configures config.subdomain, which Configuration does not define — the first snippet a new user copies raises NoMethodError.
status: resolved
tags: [auth, testing]
timestamp: 2026-08-11T18:40:00Z
---

> **Resolved in 0.2.0.** `README.md` now configures `api_host`. All three docs were updated together.
>
> Kept because it explains why the code and specs look the way they do, and what to watch for if the area is touched again.

# Overview

`README.md` opens with:

```ruby
Conexa.configure do |config|
  config.subdomain = 'YOUR_SUBDOMAIN'  # your-company.conexa.app
  config.api_token = 'YOUR_API_TOKEN'
end
```

`Conexa::Configuration` defines only `api_token` and `api_host`. Running it:

```
NoMethodError: undefined method `subdomain=' for #<Conexa::Configuration …>
```

It appears twice — `README.md:28` (Configuration) and `README.md:44` (Quick
Start). `README_pt-BR.md` and `REFERENCE.md` both use `api_host` correctly, so
this is isolated to the English README.

# Fix

Either correct the docs:

```ruby
config.api_host = 'https://mycompany.conexa.app'
```

or add the accessor people evidently expect, deriving the host from it:

```ruby
def subdomain=(value)
  @api_host = "https://#{value}.conexa.app"
end
```

The second is the friendlier API and matches how the field is described in the
comment, but it is a behaviour change; the first is correct today. See
[Authentication and configuration](../architecture/authentication.md).

Small in isolation, but it is the first code a new user runs, and a broken
quick-start reads as a broken gem.

# Citations

[1] `README.md` lines 27–30 and 43–46; `lib/conexa/configuration.rb` — gem v0.1.1.
[2] `NoMethodError` reproduced 2026-08-11.
