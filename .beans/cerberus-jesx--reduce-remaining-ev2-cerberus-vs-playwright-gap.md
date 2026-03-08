---
# cerberus-jesx
title: Reduce remaining EV2 Cerberus vs Playwright gap
status: in-progress
type: task
priority: normal
created_at: 2026-03-08T09:18:04Z
updated_at: 2026-03-08T09:40:55Z
---

## Scope

- [ ] Profile the current hottest EV2 comparison files again after the latest browser readiness changes.
- [ ] Identify the dominant remaining cost center in Cerberus browser and live drivers.
- [ ] Implement the next targeted optimization.
- [x] Re-run EV2 sequential comparison timings.
- [ ] Re-run Cerberus quality gates and commit the optimization.

## Notes\n\n- Split browser passive reads from dialog-safe action evaluates. Passive assertions/path/value/snapshot reads now use direct script.evaluate and only fall back to dialog-unblocking when a blocking prompt is actually open.\n- Added transient navigation retry to browser actions so missing browsing contexts recover like assertion reads do.\n- Aligned sql sandbox browser metadata with the ptp model: start dedicated owners when needed, encode metadata for the current test process, and support delayed owner shutdown via config :cerberus, ecto_sandbox_stop_owner_delay: 100.\n- Updated the slow browser settle test to match the new browser contract: actions budget pre-action resolve, post-change settle is left to the next assertion.\n- Current sequential EV2 comparison on project_form_feature is still 4.3s Playwright vs 17.8s Cerberus. The remaining gap is now dominated by harness behavior in ev2-copy, especially browser auth/setup and serialized browser modules, not the old evaluate_with_timeout hotspot.
