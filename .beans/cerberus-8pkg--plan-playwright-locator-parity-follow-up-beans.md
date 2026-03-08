---
# cerberus-8pkg
title: Plan Playwright locator parity follow-up beans
status: completed
type: task
priority: normal
created_at: 2026-03-08T08:50:08Z
updated_at: 2026-03-08T08:51:07Z
---

## Context

Create a structured bean breakdown for the next locator follow-up work after the aria-label cut, with enough detail to let future slices start cleanly.

## Todo

- [x] Review existing locator-related beans and avoid duplicating open work
- [x] Create one parent epic for the follow-up theme
- [x] Create detailed child beans for accessible-name semantics, broader role support, internal assertion cleanup, and parity coverage
- [x] Summarize the breakdown and mark this planning bean complete

## Summary of Changes

- Created epic cerberus-iyju to group the next locator parity follow-up work after the aria-label cut.
- Added child beans for stronger accessible-name semantics, broader role coverage, internal match_by cleanup, older text-assertion cleanup, mixed naming-source parity fixtures, and oracle coverage for aria-labelledby and accessible-name cases.
- Kept the new beans in todo status so they are ready to start as independent vertical slices.
