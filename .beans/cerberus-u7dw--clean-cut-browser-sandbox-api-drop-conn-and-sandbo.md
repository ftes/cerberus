---
# cerberus-u7dw
title: 'Clean-cut browser sandbox API: drop conn and sandbox_metadata'
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:21:10Z
updated_at: 2026-03-06T08:27:09Z
---

## Goal
Make browser sandbox setup explicit and minimal.

## Scope
- Raise on session(:browser, conn: ...)
- Remove :sandbox_metadata option entirely
- Keep browser sandbox setup only via session(:browser, user_agent: ...)
- Align docs and tests: non-browser needs no user-agent setup

## Checklist
- [x] Remove :sandbox_metadata from options/types/docs
- [x] Raise when :conn is passed to browser session
- [x] Update tests to use only :user_agent in browser mode
- [x] Update guides/examples to remove browser :conn/:sandbox_metadata setup
- [x] Run format and targeted tests

## Summary of Changes
- Removed the sandbox_metadata browser session option from public types, schema docs, and validation.
- Browser session validation now raises for disallowed options conn and sandbox_metadata.
- Removed browser driver internal sandbox_metadata state and post-start metadata override path.
- Browser SQL sandbox setup now flows only through session(:browser, user_agent: sql_sandbox_user_agent(...)).
- Updated SQL sandbox behavior and Playwright parity tests to stop seeding user-agent on non-browser conn paths.
- Updated Cerberus.sql_sandbox_user_agent docs to document browser-session wiring only.
