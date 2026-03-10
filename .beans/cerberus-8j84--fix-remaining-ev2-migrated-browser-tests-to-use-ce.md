---
# cerberus-8j84
title: Fix remaining EV2 migrated browser tests to use CerberusBrowserCase async harness
status: completed
type: task
priority: normal
created_at: 2026-03-09T18:34:34Z
updated_at: 2026-03-09T18:39:40Z
---

Audit the migrated EV2 Cerberus browser-tagged modules that still use ConnCase or async false, switch the safe ones to Ev2Web.CerberusBrowserCase with async true and sandbox_user_agent-based browser sessions, then rerun the migrated Cerberus subset.

## Summary of Changes

Converted the remaining migrated EV2 browser-tagged modules that were still using Ev2Web.ConnCase or async false onto Ev2Web.CerberusBrowserCase with async true where they already operated purely through browser sessions. Added a shared sandbox_browser_session helper to the browser case so tests consistently use context.sandbox_user_agent instead of ad hoc Browser.user_agent_for_sandbox calls. Verified the converted file subset passes (37 tests, 0 failures, 4 skipped).

A full downstream run of mix test --only cerbrerus --include integration is still not green, but the remaining failures are broader EV2 suite issues: SQL sandbox / pool pressure, owner-exit errors in LiveView/browser flows, and existing live assertion deadline failures. The harness-shape cleanup itself is in place.
