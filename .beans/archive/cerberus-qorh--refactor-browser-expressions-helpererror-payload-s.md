---
# cerberus-qorh
title: Refactor browser expressions helper/error payload snippets (increment 5)
status: completed
type: task
priority: normal
created_at: 2026-03-02T06:47:22Z
updated_at: 2026-03-02T06:48:44Z
---

## Problem
expressions.ex still repeats helper binding and error JSON payload shapes.

## TODO
- [x] Extract shared assert-helper binding snippet
- [x] Extract shared error payload snippet and apply to field/select/radio/checkbox flows
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Added assert_helper_binding_snippet/0 and applied it where `window.__cerberusAssert` was repeated.
- Added error_reason_payload/2 to centralize standard `{ ok: false, reason: ... }` response generation with optional extra fields.
- Updated indexed_lookup_snippet/4 to reuse error_reason_payload/2.
- Applied error payload helper in select/checkbox/radio guard paths, including option-specific failures.
- Verified with mix format, targeted browser suites, and mix precommit.
