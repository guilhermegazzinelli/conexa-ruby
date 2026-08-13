---
type: Runbook
title: Cutting a release
description: Version bump through gem push, what the gem actually packages, and the build warnings that 0.2.0 cleared.
tags: [release]
timestamp: 2026-08-13T03:00:00Z
---

# Overview

Releases are manual. Current version: **0.2.0** (`lib/conexa/version.rb`), the
single source — `conexa.gemspec` reads it.

# Steps

Since 0.2.0 publishing is `git push --tags`: `.github/workflows/push_gem.yml`
runs the full CI gate, checks the tag against `Conexa::VERSION`, checks what the
gem packages, and pushes via **Trusted Publishing** — GitHub's OIDC token is
exchanged for a short-lived, push-scoped RubyGems credential, so no API key is
stored anywhere. The `release` environment is where you add required reviewers.

One-time setup on RubyGems.org (needs the gem owner's account):
https://rubygems.org/gems/conexa/trusted_publishers — repository,
`push_gem.yml`, environment `release`.

1. Bump `Conexa::VERSION` in `lib/conexa/version.rb`.
2. Add a `## [x.y.z] - YYYY-MM-DD` section to `CHANGELOG.md` (Added / Changed /
   Fixed) **and** the compare link at the bottom of the file — the link list is
   maintained by hand and is easy to forget.
3. Update `README.md`, `README_pt-BR.md` and `REFERENCE.md` if the public surface
   changed. All three must move together; they have drifted before — see
   [the README quick-start defect](../defects/readme-quickstart-uses-nonexistent-subdomain.md).
4. `rake ci` — the suite on every supported ruby, then rubocop. See
   [Running the spec suite](running-the-suite.md).
5. Commit and merge.
6. `git tag vx.y.z && git push origin vx.y.z` — the workflow does the rest.

`rake release` still exists and still works from a laptop. It is how 0.1.1 was
cut, from a tree that was never committed, which is why the workflow refuses a
tag whose version does not match the code.

Built `.gem` files sit at the repo root but are ignored by `*.gitignore:1` — they
were never actually committed.

## What ships

Since 0.2.0 `spec.files` is an explicit allowlist: `lib/` plus the documentation.
Before that it packaged the whole repository, so the published gem carried
`docs/postman-collection.json` (1.7 MB) against 58 KB of library code — 0.1.1 is
163 KB, 0.2.0 is 48 KB. Check after any change to the file list:

```bash
gem build conexa.gemspec && tar xf conexa-*.gem -O data.tar.gz | tar tzf -
```

# Build warnings, resolved in 0.2.0

`gem build` used to emit the same set every release; it is now clean. Kept here
because both are easy to reintroduce.

**Open-ended dependencies.** `jwt`, `rest-client` and `multi_json` had no version
constraint, accepting any future major. `jwt` went with
[the legacy auth removal](../defects/dead-legacy-token-manager.md); the other two
are pinned to a major. That pin matters more than it looks: `multi_json`'s
adapter behaviour is load-bearing — the whole
[empty-body defect](../defects/empty-body-nomethoderror.md) turns on Oj returning
`nil` instead of raising. The development dependencies are bounded too.

**File permissions.** `lib/conexa/resources/supplier.rb` was mode `0600`. Packaged
that way the file is unreadable to anyone but the installing user, and
`require "conexa"` fails for everyone else on a shared install. Guard with:

```bash
find lib -type f ! -perm 644
```

The gemspec also specifies duplicate URI metadata (`homepage_uri` and
`source_code_uri` resolve to the same URL), which is harmless.

# Citations

[1] `lib/conexa/version.rb`, `conexa.gemspec`, `CHANGELOG.md`.
[2] `ls -l lib/conexa/resources/supplier.rb` → `-rw-------`, confirmed 2026-08-11.
