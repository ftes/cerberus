---
# cerberus-7jbf
title: Fix Firefox Realm.sys.mjs errors from popup preload
status: completed
type: bug
priority: normal
created_at: 2026-03-01T17:25:10Z
updated_at: 2026-03-01T17:31:25Z
---

Firefox logs repeated Realm.sys.mjs TypeError argument is not a global object after introducing popup_mode same_tab preload behavior.

## Scope
- Reproduce on Firefox lane.
- Identify incompatible preload logic.
- Patch popup preload to avoid Firefox Realm error while keeping same-tab behavior.
- Add/adjust tests if needed and run targeted verification.

## Todo
- [x] Reproduce and confirm error source.
- [x] Implement Firefox-safe popup override.
- [x] Run targeted tests for config + popup mode on Firefox and Chrome.
- [x] Commit bean + code changes.

## Summary of Changes
- Reproduced the Firefox Realm.sys.mjs TypeError and confirmed it was emitted when script.addPreloadScript was used for the assertion helper preload.
- Changed Firefox behavior to skip only the assertion helper preload registration, while keeping other preload scripts (including popup_mode same_tab) intact.
- Added Firefox-only lazy assertion helper bootstrap before text and path assertions by evaluating the helper script in-page.
- Verified targeted suites on Firefox and Chrome.
- Result: default Firefox browser sessions no longer emit the repeated Realm.sys.mjs error; popup_mode same_tab still may log once because it still requires preload semantics.
