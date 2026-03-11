---
# cerberus-dp3p
title: Restore toast-based parity in EV2 Cerberus copies
status: in-progress
type: task
priority: normal
created_at: 2026-03-11T08:17:14Z
updated_at: 2026-03-11T08:47:14Z
---

Remove stale migration guidance that discourages toast assertions and audit EV2 *_cerberus_test.exs files for drift where original PhoenixTest/Playwright tests asserted success toasts but the Cerberus copy switched to path or persisted-state assertions. Restore toast assertions where the originals relied on them and rerun the Cerberus-selected EV2 subset.

## Summary of Changes\n\nRemoved stale toast-avoidance guidance from MIGRATE_FROM_PHOENIX_TEST.md and improved Cerberus live post-action snapshot handling: normal live action results now reuse the current LiveView tree instead of reparsing returned HTML strings, redirect handling preserves redirect flash cookies, and redirected live snapshots use LiveViewTest runtime helpers rather than the older follow_get-only path. This did not fully close the remaining EV2 live toast parity gap, but it is a clean Cerberus-side improvement and keeps the Cerberus suite green.
