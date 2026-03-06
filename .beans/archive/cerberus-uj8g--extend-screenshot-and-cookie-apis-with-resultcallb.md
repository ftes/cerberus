---
# cerberus-uj8g
title: Extend screenshot and cookie APIs with result/callback behavior
status: completed
type: feature
priority: normal
created_at: 2026-03-05T09:47:37Z
updated_at: 2026-03-05T09:55:43Z
---

Implement screenshot enhancements and cookie callback forms.

## Todo
- [x] Audit current screenshot/cookie API and driver internals
- [x] Add screenshot options for binary result and open-in-viewer behavior
- [x] Add screenshot callback form receiving binary
- [x] Add callback overloads for cookies/cookie/session_cookie while keeping value-return defaults
- [x] Update typespecs/options/docs and tests
- [x] Run format and targeted tests

## Summary of Changes
- Extended `Options.screenshot_opts` and screenshot schema with `open: boolean` and `return_result: boolean`.
- Enhanced `Browser.screenshot` to support:
  - callback overload receiving PNG binary (`screenshot(session, opts_or_path, fn binary -> ... end)`),
  - `return_result: true` returning PNG binary,
  - `open: true` opening the saved screenshot via system viewer command.
- Added internal screenshot helpers in `Browser` to capture a resolved path once, read binary, and optionally open via configurable opener (`:cerberus, :open_with_system_cmd`, defaulting to `Cerberus.OpenBrowser.open_with_system_cmd/1`).
- Added callback overloads for `Browser.cookies/2`, `Browser.cookie/3`, and `Browser.session_cookie/2` while preserving existing value-returning defaults for `/1` and `/2` lookup forms.
- Updated docs cheat sheet with screenshot binary/open and cookie callback examples.
- Added regression coverage for screenshot callback/return/open behavior and cookie callback overloads.

- Follow-up docs sync: updated README and docs/getting-started snippets to mention screenshot `open: true`, screenshot `return_result: true`, and cookie callback usage.
