---
# cerberus-r04r
title: 'Browser config: global viewport, user-agent, and init JS hooks'
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:07:18Z
updated_at: 2026-02-28T07:36:53Z
parent: cerberus-ykr0
---

Add global browser configuration for display size, user agent, and JavaScript that runs on each new session and/or tab.

## Todo
- [x] Add browser-context default normalization for viewport, user-agent, and init scripts.
- [x] Apply defaults when browser user contexts are created.
- [x] Ensure defaults apply to newly opened tabs in the same user context.
- [x] Add unit and browser integration coverage.

## Summary of Changes
- Added browser-context defaults handling in `Cerberus.Driver.Browser` via `browser_context_defaults/1`.
- Added support for:
  - `browser: [viewport: [width: ..., height: ...] | {w, h}]`
  - `browser: [user_agent: "..."]`
  - `browser: [init_script: "..."]` and `browser: [init_scripts: ["...", ...]]`
- Wired defaults into `UserContextProcess` initialization:
  - applies user-agent override per user context,
  - registers preload init scripts via BiDi,
  - passes viewport defaults into each new browsing context.
- Added viewport application at browsing-context creation (`browsingContext.setViewport`).
- Added tests:
  - normalization unit coverage in `test/cerberus/driver/browser/config_test.exs`,
  - browser integration check in `test/cerberus/public_api_test.exs` verifying init script + viewport across tabs.
