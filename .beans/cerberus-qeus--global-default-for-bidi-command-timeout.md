---
# cerberus-qeus
title: Global default for BiDi command timeout
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:11:06Z
updated_at: 2026-02-28T08:06:08Z
---

Expose a global/default timeout for WebDriver BiDi commands and preserve per-command overrides.

## Summary of Changes

- Added a configurable default BiDi command timeout via `config :cerberus, :browser, bidi_command_timeout_ms`.
- Kept per-command `timeout:` as highest-precedence override in `Cerberus.Driver.Browser.BiDi.command/4`.
- Added timeout default coverage in `test/cerberus/timeout_defaults_test.exs` for global default, browser opts override, and per-command override precedence.
- Updated README timeout defaults documentation to include the new browser config key and precedence note.
