---
# cerberus-flcn
title: Make ambiguous actions strict across drivers
status: completed
type: bug
priority: normal
created_at: 2026-03-10T18:05:43Z
updated_at: 2026-03-10T18:45:12Z
---

Implement a shared strict action-selection contract so static, live, and browser actions raise when a locator matches multiple elements unless first/last/nth/index is provided. Convert the current ambiguity coverage into parity tests, rerun focused suites and the affected EV2 Cerberus copy, and update the bean with a summary when done.

## Summary of Changes

Implemented a shared strict action-selection contract across static, live, and browser drivers so actions now raise when a locator matches multiple elements unless first, last, nth, or index is provided. Reworked the shared action finders and browser action resolution to use the same ambiguity rule, converted duplicate-link/button/field coverage into parity tests, and aligned the locator parity corpus to the new locator-first contract so ambiguous text and label actions now fail instead of silently narrowing to form fields.

Verified with focused parity suites and a full Cerberus gate (`source .envrc && PORT=4964 MIX_ENV=test mix do format + precommit + test + test --only slow`), which finished green with 597 tests and 0 failures. Reran the downstream EV2 Cerberus-selected subset and confirmed the ambiguity contract itself is no longer the blocker; the remaining red row is a separate sandbox ownership/lifetime failure in `dashboard_live/index_cerberus_test.exs`.
