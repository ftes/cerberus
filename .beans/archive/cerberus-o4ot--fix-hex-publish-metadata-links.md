---
# cerberus-o4ot
title: Fix Hex publish metadata links
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:32:44Z
updated_at: 2026-02-27T22:33:31Z
---

## Objective
Resolve mix hex.publish metadata warning/error for missing package links.

## Done When
- [x] mix.exs package metadata includes links.
- [x] mix hex.publish check no longer reports missing links metadata.
- [x] formatting is clean.

## Summary of Changes
- Added required Hex package metadata links in mix.exs package metadata: GitHub => https://github.com/ftes/cerberus.
- Ran mix format.
- Verified with mix hex.publish --dry-run; package metadata now includes Links and no longer errors with missing links.
