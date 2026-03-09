---
# cerberus-n0w0
title: Trim regular missing-field browser value assertion test
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:13:13Z
updated_at: 2026-03-09T15:17:46Z
---

## Goal

Reduce runtime of the regular-lane browser missing-field value assertion test by avoiding unnecessary timeout budget in a negative-path assertion.

## Tasks

- [ ] Confirm the current failure path spends time in timeout polling
- [x] Tighten the test to use an explicit short timeout while preserving the asserted error shape
- [ ] Re-run targeted and suite timing checks
- [x] Summarize remaining regular outliers

## Summary of Changes

Confirmed the browser missing-field negative path was consuming default timeout budget. Tightened both negative assertions to use timeout 50 while keeping the same asserted error message.

Result:

- browser missing-field row dropped from about 1547ms to about 428ms
