---
# cerberus-t81a
title: Design first-class multi-window lifecycle API
status: completed
type: feature
priority: normal
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-03-02T08:39:12Z
---

Gap scope: no first-class APIs for popup/new-window handles, switching, waiting, and close/return flows.

## Scope
- Propose API shape and lifecycle semantics
- Cover practical scenarios (OAuth popup, preview/export windows)
- Add conformance tests for deterministic window switching behavior

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.

## TODO
- [x] Add Browser.with_popup/4 public API with browser-only unsupported behavior on non-browser sessions
- [x] Implement Extensions.with_popup/4 deterministic popup capture and main-session restore flow
- [x] Retrofit Browser.with_dialog/3 to ignore callback return and return canonical refreshed main session
- [x] Add fixture route/page for deterministic click-triggered popup opening
- [x] Add/adjust browser extension tests for with_popup and with_dialog semantics
- [x] Update README, cheatsheet, and browser support policy docs
- [x] Run format, targeted browser tests, and precommit
- [x] Add summary of changes

## Summary of Changes
- Added Browser.with_popup/4 as a browser-only API with trigger callback (arity 1), interaction callback (arity 2), timeout validation, and unsupported assertions on non-browser sessions.
- Implemented Cerberus.Driver.Browser.Extensions.with_popup/4 with deterministic popup capture, trigger/callback error surfacing, callback return ignore semantics, and canonical main-session return after main-tab restore and path refresh.
- Retrofitted with_dialog/3 to ignore callback return value and always return refreshed canonical main session after restoring the original tab.
- Added deterministic popup click fixture route/page (/browser/popup/click) for user-action popup capture tests.
- Added and updated browser extension tests for with_popup happy path/timeout/callback failure, non-browser unsupported behavior, and with_dialog return semantics.
- Added minimal browser runtime support for attaching externally opened popup tabs by allowing context attachment in BrowsingContextProcess and exposing UserContextProcess.attach_tab/2.
- Updated docs in README.md, docs/cheatsheet.md, and docs/browser-support-policy.md to document popup lifecycle callback-pair semantics and browser-only scope.
- Ran mix format, targeted browser tests, popup mode regression tests, and mix precommit with configured Chrome/Firefox binaries.
