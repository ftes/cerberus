---
# cerberus-x0v4
title: Make locator exactness default to true
status: in-progress
type: feature
created_at: 2026-03-04T22:03:31Z
updated_at: 2026-03-04T22:03:31Z
---

## Goal
Default all locator matching to exact when no explicit exact flag/modifier is provided.

## Tasks
- [ ] Update locator normalization defaults to exact:true (helpers, map/keyword input, sigil without exact modifier)
- [ ] Update tests/docs that currently assume implicit inexact matching
- [ ] Run targeted + slow verification suites with random test port
