---
# cerberus-2rdp
title: Remove show_browser and add slow_mo browser runtime option
status: completed
type: feature
priority: normal
created_at: 2026-03-04T09:28:47Z
updated_at: 2026-03-04T09:40:38Z
---

Clean-cut remove show_browser from API/options/docs/tests and rely on headless only. Implement Playwright-style slow_mo delay for browser actions/runtime commands.\n\nScope:\n- [x] Remove show_browser from options schemas, validation, runtime behavior, bootstrap env wiring, and docs/tests\n- [x] Add slow_mo option to browser session/runtime config and types/docs\n- [x] Apply slow_mo delay in browser driver command flow (Playwright-style per action/command pacing)\n- [x] Add/update tests for headless-only semantics and slow_mo behavior\n- [x] Run format, targeted browser-inclusive tests, and precommit

## Summary of Changes

- Removed `show_browser` from browser option schemas/types and runtime headless semantics; `headless` is now the single launch visibility control.
- Added `slow_mo` (ms) to browser session/runtime options, docs, and test bootstrap env wiring (`SLOW_MO`).
- Implemented Playwright-style slow-motion pacing in BiDi command dispatch and propagated per-session BiDi runtime options through browser session state so extension calls (including `evaluate_js`) honor `slow_mo`.
- Updated runtime and explicit-browser tests to validate headless-only behavior and command pacing.
- Updated docs/examples to use `headless: false` and document `slow_mo` usage.
