---
type: Runbook
title: Running the spec suite
description: rake, rake spec:all across every supported Ruby, and why there is a .rubocop_todo.yml and no committed Gemfile.lock.
tags: [testing, release]
timestamp: 2026-08-12T18:30:00Z
---

# Overview

Expected result: **615 examples, 0 failures** (gem v0.2.0), on every supported
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
rake spec:all   # 3.1.7, 3.2.9, 3.3.10, 3.4.7 via mise
rake ci         # the above, then rubocop
```

`SUPPORTED_RUBIES` in the `Rakefile` is the single list; keep it in step with
`.github/workflows/ruby.yml` and the gemspec's `required_ruby_version`.

One `BUNDLE_PATH` per version (`vendor/bundle-3.1.7`, ...): native extensions are
not portable across Ruby versions, and sharing `vendor/bundle` makes each run
clobber the last.

**`Gemfile.lock` is not committed**, which is the convention for a gem and the
thing that makes this matrix meaningful — each version resolves the range the
gemspec allows instead of one pinned set. CI used to `rm -f` the lockfile before
`bundle install` for exactly this reason.

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

# RuboCop, and why there is a todo file

`rake` runs `spec` then `rubocop`, and until 0.2.0 it **failed**: ~2000
pre-existing offences, ~1540 of them `Style/StringLiterals` from a codebase that
mixes quote styles under a config enforcing double quotes. A default task that
always fails is a default task nobody runs, which is why CI carried
`continue-on-error: true` on lint.

`.rubocop_todo.yml` (generated, committed) grandfathers those offences per file.
The effect is that **new** code is genuinely linted while the backlog stays
visible, `rake` passes, and CI gates on lint for real. Autocorrecting the backlog
is separate work — doing it inside a behavioural release would bury the fixes in
a repo-wide diff.

Regenerate after clearing a batch:

```bash
bundle exec rubocop --auto-gen-config --no-exclude-limit
```

# HTTP is blocked by default

`spec_helper.rb` sets VCR's `allow_http_connections_when_no_cassette = false`
and hooks into WebMock, so any unstubbed request fails loudly rather than
reaching a real tenant. Keep it that way: several specs exercise
[charge settlement](../api/charge-settlement.md), which moves money.

# Citations

[1] `Gemfile`, `conexa.gemspec`, `.rspec`, `spec/spec_helper.rb`, `Rakefile`.
[2] Build failure and workaround reproduced 2026-08-11 on Ruby 3.1.7 (mise), Arch Linux.
