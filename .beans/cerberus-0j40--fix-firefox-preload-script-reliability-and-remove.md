---
# cerberus-0j40
title: Fix Firefox BiDi preload scripts (remove skip + runtime helper checks)
status: completed
type: task
priority: normal
created_at: 2026-03-03T11:23:25Z
updated_at: 2026-03-03T19:05:54Z
parent: cerberus-dsr0
---

Replace the current Firefox-specific runtime helper preload checks with reliable preload-script installation for assertion/action helpers.\n\nScope:\n- [x] Reproduce and characterize current Firefox preload-script failure modes\n- [x] Implement robust preload-script setup path for Firefox user contexts\n- [x] Remove Firefox per-call helper preload checks from browser driver action/assertion flows\n- [x] Validate browser suites on Firefox and Chrome\n- [x] Update docs/comments about Firefox preload behavior

\nAcceptance:\n- [x] Remove or retire skip_firefox_problematic_preload?/2 for FF once BiDi preload is reliable\n- [x] Ensure assertion/action/popup preload helpers are installed at context setup on FF, matching Chrome behavior\n- [x] Keep helper-version invalidation semantics intact across browsers

## Summary of Changes
- Removed the per-action helper ensure hook from browser action execution so helper usage is fully preload-based.
- Removed Firefox-specific same-tab popup mode rejection in browser config, aligning helper preload behavior across Chrome and Firefox.
- Cleaned up preload-related docs by removing outdated Firefox limitation notes in README popup behavior guidance.
- Verified updated behavior with browser config/runtime suites and chrome action/link suites; Firefox full browser-suite execution remains policy-deferred while Firefox config/runtime paths are covered.
