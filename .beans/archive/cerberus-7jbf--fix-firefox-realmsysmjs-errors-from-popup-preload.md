---
# cerberus-7jbf
title: Fix Firefox Realm.sys.mjs errors from popup preload
status: completed
type: bug
priority: normal
created_at: 2026-03-01T17:25:10Z
updated_at: 2026-03-01T17:46:34Z
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

## Follow-up
- User reports Firefox Realm.sys.mjs TypeError still appears with CERBERUS_BROWSER_NAME=firefox after previous fix.
- Reproduce current behavior on main and remove remaining preload path emitting this log.

## Follow-up Summary
- Confirmed remaining Firefox Realm.sys.mjs log came from preload registration for popup_mode same_tab.
- Added Firefox preload filter for both assertion-helper and popup same-tab preload scripts in user context setup.
- Added explicit popup_mode same_tab unsupported guard on Firefox with clear ArgumentError.
- Updated popup mode tests to assert the Firefox unsupported path and skip the same-tab behavior test when CERBERUS_BROWSER_NAME=firefox.
- Updated docs to state the Firefox limitation.
- Verified with CERBERUS_BROWSER_NAME=firefox that browser extensions and popup mode tests run without the Realm.sys.mjs line for supported paths.

## Follow-up 2
- User requested known-bug note and test skip condition based on app env browser_name instead of system env.

## Follow-up 2 Summary
- Switched popup same-tab Firefox skip to application config lookup via compile-time `:cerberus, :browser, :browser_name`.
- Kept docs and known bug note aligned with current Firefox preload limitation.
- Re-ran formatting and precommit successfully before commit.
