---
# cerberus-kwt0
title: Re-measure EV2 performance and simplify browser driver if needed
status: in-progress
type: task
priority: normal
created_at: 2026-03-08T09:03:34Z
updated_at: 2026-03-08T09:17:18Z
---

## Scope

- [x] Re-run the restored EV2 original vs Cerberus timing comparisons after the latest browser-driver changes.
- [x] Summarize the updated Playwright/PhoenixTest vs Cerberus gap.
- [x] Inspect the browser driver for leftover complexity/stale readiness plumbing after the semantic changes.
- [x] If cleanup is justified, implement a targeted simplification/refactor and verify it.
- [ ] Commit only the relevant Cerberus changes and bean files.

## Notes

Updated EV2 sequential mix-test timings using the restored comparison files:
- project_form_feature: Playwright 4.7s vs Cerberus 16.4s (about 3.5x slower)
- register_and_accept_offer: Playwright 4.3s vs Cerberus 18.3s (about 4.3x slower)
- notifications: PhoenixTest 2.4s vs Cerberus 13.6s (about 5.7x slower)

Browser-driver simplification/refactor completed in this pass:
- removed the public current_path API and session accessors from Cerberus.Session
- switched browser reload_page to real browsingContext.reload semantics
- renamed stale browser action-settling helpers to match the new navigation-only wait model
- kept the one remaining inLiveRoot helper needed for live multi-select accumulation
- updated path-oriented tests to use assert_path rather than eager session path reads

Verification:
- source .envrc && PORT=4938 MIX_ENV=test mix do format + precommit + test + test --only slow
- passed: 564 tests, 0 failures, 2 skipped (31 excluded)
