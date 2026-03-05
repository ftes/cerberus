---
# cerberus-lnwn
title: Upstream NBSP normalization into core text matcher
status: completed
type: bug
priority: normal
created_at: 2026-03-05T13:44:34Z
updated_at: 2026-03-05T13:46:03Z
---

Normalize NBSP in Cerberus.Query so static/live text matching aligns with browser helper and shim retries are unnecessary for this class of mismatch.

## Summary of Changes
- Updated Cerberus.Query maybe_normalize_ws to normalize NBSP and narrow NBSP (U+00A0, U+202F) before whitespace collapsing.
- Added Query.match_text coverage in test/cerberus/query_test.exs for NBSP normalization and normalize_ws false behavior.
- Verified with:
  - direnv exec . env PORT=4118 mix test test/cerberus/query_test.exs
  - direnv exec . env PORT=4123 mix test test/cerberus/form_actions_test.exs
