---
type: Runbook
title: Running the spec suite
description: bundle exec rspec fails on this machine because the debug gem's io-console dependency will not compile — use the workaround Gemfile.
tags: [testing, release]
timestamp: 2026-08-11T18:40:00Z
---

# Overview

Expected result: **594 examples, 0 failures** (gem v0.2.0), on every supported
Ruby.

Since 0.2.0 the suite also checks the gem against the published API contract, not
only against itself — see
[stubbed specs hide contract drift](../decisions/stubbed-specs-hide-contract-drift.md).

```bash
bundle exec rspec
```

`.rspec` supplies `--require spec_helper`, so no extra flags are needed.
`rake` runs `spec` then `rubocop`.

# Every supported Ruby

```bash
claude_scripts/multi_ruby_specs/run.sh          # 3.1.7, 3.2.9, 3.3.10, 3.4.7
claude_scripts/multi_ruby_specs/run.sh --lint   # plus rubocop
```

One `BUNDLE_PATH` per version: native extensions are not portable across Ruby
versions, and sharing `vendor/bundle` makes each run clobber the last.

# If `bundle install` fails on io-console

Before 0.2.0, `bundle exec rspec` could not start at all on Ruby 3.1.7 with a
current GCC:

```
Could not find debug-1.9.2, irb-1.14.1, reline-0.7.0, io-console-0.7.2 …
make: *** [Makefile:249: console.o] Error 1
```

The chain was `conexa.gemspec` → `debug` (a *development dependency*) → `irb` →
`reline` → `io-console`, whose `console.c` does not compile against that Ruby's
`rb_define_method` prototypes, with no pure-Ruby fallback. Nothing in the suite
uses `debug`; it is a REPL convenience that was able to block every contributor's
test run.

0.2.0 fixed the structure rather than documenting a workaround:

- the gemspec's development dependencies land in bundler's **`:test`** group
  (`gemspec development_group: :test` in the `Gemfile`);
- `debug` and `byebug` moved to an optional **`:development`** group and out of
  the gemspec entirely.

So if the extension will not build on your Ruby, skip the group:

```bash
BUNDLE_WITHOUT=development bundle install
BUNDLE_WITHOUT=development bundle exec rspec
```

The multi-Ruby script sets that automatically.

# RuboCop is not clean, by long standing

`bundle exec rubocop` reports ~2000 offences, of which ~1540 are
`Style/StringLiterals` — the codebase mixes quote styles and the config enforces
double quotes. CI runs lint with `continue-on-error: true`, which is the honest
reflection of that. Autocorrecting is a separate piece of work: doing it inside a
behavioural release would bury the actual fixes in a repo-wide diff.

# HTTP is blocked by default

`spec_helper.rb` sets VCR's `allow_http_connections_when_no_cassette = false`
and hooks into WebMock, so any unstubbed request fails loudly rather than
reaching a real tenant. Keep it that way: several specs exercise
[charge settlement](../api/charge-settlement.md), which moves money.

# Citations

[1] `Gemfile`, `conexa.gemspec`, `.rspec`, `spec/spec_helper.rb`, `Rakefile`.
[2] Build failure and workaround reproduced 2026-08-11 on Ruby 3.1.7 (mise), Arch Linux.
