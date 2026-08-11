---
type: Decision
title: Default to limit/offset pagination
description: v0.1.0 made limit/offset the default and kept page/size behind a deprecation warning — a breaking change to the return of every listing call, with a removal date of 2026-08-01 that has now passed.
tags: [pagination, legacy]
timestamp: 2026-08-11T18:40:00Z
---

# Overview

Released in **v0.1.0 (2026-03-31)**, described in the changelog as breaking.

Before: `.all` and `.find_by` with no arguments sent `page: 1, size: 100`.
After: they send `limit: 100, offset: 0`, and `page`/`size` apply only when
passed explicitly, with a deprecation warning.

Shipped alongside it: `limit`/`offset` validation, `Result#has_next?` and
`Result#next_page`, and a migration guide in both READMEs and `REFERENCE.md`. See
[Pagination and the Result object](../architecture/pagination.md).

# Why

The v1-era `page`/`size` parameters do not work against API v2 — the API
validates `page` and then always returns the first page. That was only fully
characterised later, in
[page is accepted and silently ignored](../defects/page-param-silently-ignored.md),
but the direction was already right: `offset` is the only parameter the API
actually honours.

# Trade-off taken

Changing a default is a silent behaviour change for existing callers — no
warning fires on the *new* path, only on the legacy one. The migration was
accepted anyway because the old default produced wrong results, and a wrong
answer is worse than a changed one.

# Closed in 0.2.0: the expired window

The original warning promised removal on **2026-08-01**, a date that passed while
`page`/`size` still *appeared* to work — returning page 1 forever.

0.2.0 took a third option over removing or raising: **convert**. `page`/`size`
become `limit`/`offset` (`offset = (page - 1) * size`), the warning now names the
real problem and points at 0.3.0 for removal, and invalid values raise. The
reasoning is that a caller on the legacy path is already receiving wrong data;
converting fixes them silently, whereas raising would break code that at least
ran. See [page is accepted and silently
ignored](../defects/page-param-silently-ignored.md).

# Citations

[1] `CHANGELOG.md`, v0.1.0 — 2026-03-31.
[2] `lib/conexa/model.rb` (`extract_page_size_or_params`), warning text with the 2026-08-01 date.
