---
type: Runbook
title: Cutting a release
description: Version bump, changelog, tag, build, push — plus the two build warnings this gem emits every time and what they actually mean.
tags: [release]
timestamp: 2026-08-11T13:23:00Z
---

# Overview

Releases are manual. Current version: **0.1.1** (`lib/conexa/version.rb`), the
single source — `conexa.gemspec` reads it.

# Steps

1. Bump `Conexa::VERSION` in `lib/conexa/version.rb`.
2. Add a `## [x.y.z] - YYYY-MM-DD` section to `CHANGELOG.md` (Added / Changed /
   Fixed) **and** the compare link at the bottom of the file — the link list is
   maintained by hand and is easy to forget.
3. Update `README.md`, `README_pt-BR.md` and `REFERENCE.md` if the public surface
   changed. All three must move together; they have drifted before — see
   [the README quick-start defect](../defects/readme-quickstart-uses-nonexistent-subdomain.md).
4. Run the suite — [Running the spec suite](running-the-suite.md).
5. Commit, tag `vx.y.z`, `gem build conexa.gemspec`.
6. Push the branch and the tag; publish with `gem push conexa-x.y.z.gem`.

Built `.gem` files are currently committed at the repo root (`conexa-0.0.8`
through `conexa-0.1.1`). That is unusual — they are build artifacts and belong in
a release attachment or `.gitignore`, not in git.

# Build warnings that recur

`gem build` emits the same two every release. Neither blocks the build; one is
a real bug.

**Open-ended dependencies.** `jwt`, `rest-client` and `multi_json` are declared
with no version constraint, so any future major release of any of them is
accepted. `multi_json`'s adapter behaviour is load-bearing here — the whole
[empty-body defect](../defects/empty-body-nomethoderror.md) turns on Oj returning
`nil` instead of raising. Pin at least a major.

**File permissions.** `lib/conexa/resources/supplier.rb` is mode `0600`. Packaged
that way, the file is unreadable to anyone but the installing user, and
`require "conexa"` fails for everyone else on a shared install. Fix it:

```bash
chmod 0644 lib/conexa/resources/supplier.rb
```

The gemspec also specifies duplicate URI metadata (`homepage_uri` and
`source_code_uri` resolve to the same URL), which is harmless.

# Citations

[1] `lib/conexa/version.rb`, `conexa.gemspec`, `CHANGELOG.md`.
[2] `ls -l lib/conexa/resources/supplier.rb` → `-rw-------`, confirmed 2026-08-11.
