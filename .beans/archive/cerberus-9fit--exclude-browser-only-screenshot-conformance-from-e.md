---
# cerberus-9fit
title: Exclude browser-only screenshot conformance from --exclude browser runs
status: completed
type: bug
priority: normal
created_at: 2026-02-28T07:52:23Z
updated_at: 2026-02-28T07:56:46Z
---

Fix screenshot conformance test behavior so mix test --exclude browser does not execute browser-only screenshot flow and fail on BiDi readiness/timeouts.

## Summary of Changes

- Split screenshot conformance coverage into two tests:
  - static/live unsupported behavior test tagged `drivers: [:static, :live]`
  - browser PNG behavior test tagged `@tag browser: true` + `drivers: [:browser]`
- Fixed locator-driven CSS click flow for action normalization so selector survives option validation and matching.
  - CSS locator normalization now sets selector in operation opts as well as locator opts.
- Verified:
  - `mix test test/core/screenshot_conformance_test.exs --exclude browser`
  - `mix test --exclude browser`
  - `mix test`
