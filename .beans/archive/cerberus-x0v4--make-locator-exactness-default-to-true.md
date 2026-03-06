---
# cerberus-x0v4
title: Make locator exactness default to true
status: completed
type: feature
priority: normal
created_at: 2026-03-04T22:03:31Z
updated_at: 2026-03-06T20:17:22Z
---

## Goal
Default all locator matching to exact when no explicit exact flag/modifier is provided.

## Tasks
- [x] Update locator normalization defaults to exact:true (helpers, map/keyword input, sigil without exact modifier)
- [x] Update tests/docs that currently assume implicit inexact matching
- [x] Run targeted + slow verification suites with random test port

## Summary of Changes
- Defaulted locator normalization to exact matching when no explicit exact flag is provided.
- Updated locator docs and tests for exact-by-default behavior and verified focused suites with a randomized PORT.
