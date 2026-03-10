---
# cerberus-me6s
title: Replace remaining return_result APIs with explicit split
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T06:06:19Z
updated_at: 2026-03-10T06:11:55Z
---

## Goal

Remove the remaining return_result-style APIs and replace them with explicit result-returning functions plus pipe-preserving wrappers.

## Todo

- [x] Split render_html into explicit result and callback/pipe forms
- [x] Split Browser.screenshot into explicit result and callback/pipe forms
- [x] Remove shared return_result option/schema if no longer used
- [x] Update docs and tests for the clean cut
- [ ] Run format and targeted tests

## Notes

- mix format passed.
- Targeted mix test is currently blocked by an unrelated compile error in lib/cerberus/driver/live.ex:150 calling undefined refresh_live_document!/1.
