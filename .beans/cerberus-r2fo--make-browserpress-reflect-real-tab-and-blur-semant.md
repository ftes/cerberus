---
# cerberus-r2fo
title: Make Browser.press reflect real Tab and blur semantics
status: completed
type: bug
priority: normal
created_at: 2026-03-06T22:18:05Z
updated_at: 2026-03-08T07:15:25Z
---

## Context

While migrating EV2 browser tests from Playwright to Cerberus, one test relied on pressing Tab after filling a blur-debounced input. In Cerberus browser extensions, Browser.press currently only dispatches keydown and keyup on the resolved target. It does not perform browser-like focus navigation or blur behavior.

Concrete EV2 example:
- test/features/create_offer_test.exs resets a New job title field after department changes
- the New job title input uses phx-debounce blur
- the old Playwright flow pressed Tab on the field and the blur-triggered LiveView behavior ran
- the Cerberus migration could not rely on Browser.press with key Tab because the input stayed effectively unblurred
- the EV2 test had to work around this by clicking a label to move focus instead

## Why this matters

This is a browser parity gap, not just an EV2 quirk. Tests that depend on blur-triggered validation or LiveView change handling should not need custom focus-shift workarounds when using Browser.press with Tab.

## Expected behavior

- Browser.press on Tab should produce real focus movement when possible
- the previously focused field should receive blur-related effects
- blur-debounced LiveView flows should observe the same semantics as a user tabbing away
- non-Tab keys should still behave sensibly and not regress existing uses

## Suggested scope

- add a focused browser regression covering a blur-debounced input that changes state after Tab
- decide whether to implement proper Tab focus traversal or at least blur the active target for Tab when a selector is provided
- rerun targeted Cerberus browser tests
- remove the EV2 workaround if the new semantics make it unnecessary

## Notes

The migration workaround proved that the app behavior itself is fine. The gap is in Cerberus Browser.press semantics.

## Summary of Changes

- Replaced Browser.press synthetic DOM KeyboardEvent dispatch with real BiDi keyboard actions scoped to the current browsing context.
- Reworked Browser.type to focus the target, optionally clear it, and then send real keyboard input instead of mutating value/text directly.
- Added key normalization for Playwright-style named keys, modifier chords, printable keys, and editing/navigation keys.
- Added browser regression coverage for real keydown typing, printable press behavior, Backspace editing, and Tab-driven blur/focus traversal.
- Updated the browser extensions fixture to expose keyboard event counts and blur/focus state needed for the regressions.
- Verified with mix precommit, the full test suite, and the slow suite.
