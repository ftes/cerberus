---
# cerberus-evmr
title: 'Remote browser mode: connect without local browser launch'
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:07:18Z
updated_at: 2026-02-28T08:29:52Z
parent: cerberus-ykr0
---

Design and implement remote-browser connection mode (connect to pre-running browser) and decide whether chromedriver is local, remote, or unnecessary in each mode.

## Summary of Changes

- Added remote WebDriver runtime mode via `webdriver_url` (session opts or `config :cerberus, :browser`) so Cerberus connects to a pre-running endpoint without launching local Chrome/ChromeDriver.
- Kept backward compatibility by treating `chromedriver_url` as a legacy fallback for external WebDriver URL resolution.
- Updated runtime session capability payload building to support managed vs remote services:
  - managed local mode includes local Chrome binary in `goog:chromeOptions`,
  - remote mode omits local binary requirement and only uses explicit `chrome_args`.
- Added runtime tests for URL precedence and managed vs remote capability payload behavior.
- Updated user/docs guidance to clarify local vs remote runtime requirements and behavior.
