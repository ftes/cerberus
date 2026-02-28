---
# cerberus-e4sp
title: Add 4-lane browser CI matrix (local/ws x chrome/firefox)
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T20:40:01Z
updated_at: 2026-02-28T20:52:35Z
---

Restructure CI to run browser-tagged tests in four lanes: local chrome, local firefox, websocket chrome, websocket firefox. Minimize duplicate setup via shared non-browser setup and reusable matrix job steps.

## Implementation Checklist

- [x] Create dedicated explicit browser test module tagged explicit_browser
- [x] Keep default browser tests on :browser and remove explicit lane overrides from shared suites
- [x] Add CI browser matrix for local/ws x chrome/firefox regular browser tests
- [x] Add separate explicit-browser CI lane with both local browsers installed
- [x] Update docs/examples that reference moved tests
- [x] Run format and targeted validation commands

## Work Log

- Reviewed existing CI workflow, browser install scripts, and current explicit browser-tagged tests.

- Ran validation: mix precommit; mix test.websocket --browsers chrome,firefox test/core/explicit_browser_test.exs; mix test.websocket --browsers chrome test/core/browser_tag_showcase_test.exs; local chrome lane for browser_tag_showcase passes.
