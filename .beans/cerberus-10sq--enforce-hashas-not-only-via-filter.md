---
# cerberus-10sq
title: Enforce has/has_not only via filter
status: in-progress
type: task
created_at: 2026-03-06T10:36:25Z
updated_at: 2026-03-06T10:36:25Z
---

## Goal
Make a clean API cut: has/has_not accepted only in filter/2, rejected everywhere else.

## Todo
- [ ] Audit locator/options normalization and constructors for direct has/has_not acceptance
- [ ] Remove direct has/has_not support outside filter/2
- [ ] Update tests/docs for strict behavior
- [ ] Run targeted tests with source .envrc and random PORT
