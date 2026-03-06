---
# cerberus-t21j
title: Fix static submit nested form param encoding
status: completed
type: bug
priority: normal
created_at: 2026-03-04T18:25:39Z
updated_at: 2026-03-04T18:31:44Z
---

Confirm and fix static form submit payload encoding so nested fields like session[email] submit as session => %{email: ...}. Add parity tests for static/live/browser submit payload shape.

## Summary of Changes
- Fixed static non-GET form submit normalization so bracketed keys (for example session[email]) are converted to nested maps before request dispatch.
- Kept GET submits unchanged to preserve query-string building behavior for existing nested GET forms.
- Added a nested POST fixture route and a cross-driver parity test that asserts nested params are received under session and flat bracket keys are absent.
- Verified with targeted tests for form actions parity, nested GET profile flow, and static upload POST flow.
