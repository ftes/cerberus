---
# cerberus-h2r4
title: Debug ev2-copy Firefox session initialization
status: completed
type: bug
priority: normal
created_at: 2026-03-12T08:43:41Z
updated_at: 2026-03-12T09:14:49Z
---

Debug why ev2-copy Cerberus sessions fail under Firefox and fix the underlying issue.

- [x] reproduce the Firefox session initialization failure with a minimal command
- [x] trace the Cerberus Firefox startup path to the failing call
- [x] patch the underlying bug
- [x] verify Cerberus and ev2-copy Firefox session startup
- [x] summarize results and follow-ups

## Summary of Changes

- fixed Cerberus direct Firefox BiDi startup by creating a BiDi session before `browser.createUserContext`
- verified Cerberus Firefox browser sessions start locally without geckodriver
- removed the `../cerberus` fallback from `ev2-copy` test config and replaced it with a dedicated local override via `CERBERUS_FIREFOX_BINARY`
- documented the local override in `ev2-copy/.envrc.sample`
- confirmed `ev2-copy` resolves Firefox correctly even when `FIREFOX` is set to a missing path

## Follow-up

- `ev2-copy` still has a separate Firefox login-flow failure after submit; startup/config is no longer the blocker
