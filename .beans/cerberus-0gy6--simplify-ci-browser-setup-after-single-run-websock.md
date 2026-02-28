---
# cerberus-0gy6
title: Simplify CI browser setup after single-run websocket dual-browser support
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:15:58Z
updated_at: 2026-02-28T20:16:37Z
---

## Goal
Remove redundant local browser setup/steps in CI now that websocket mode can run chrome+firefox in one invocation.

## Todo
- [x] Identify redundant browser setup and duplicate coverage in CI
- [x] Update workflow to keep one browser lane strategy
- [x] Validate workflow syntax and summarize changes
- [x] Mark bean complete

## Summary of Changes
- Removed CI browser-tools cache step that was only needed for local Chrome/Firefox binary provisioning.
- Removed explicit local browser runtime preparation step (`check_chrome_bidi_ready.sh` / `check_firefox_bidi_ready.sh` and env exports).
- Removed local browser conformance run (`mix test --only conformance --only browser --exclude remote_webdriver`).
- Kept websocket dual-browser run (`mix test.websocket --browsers chrome,firefox`) as the single browser lane strategy.

## Validation
- Workflow edited to remove redundant local browser setup while retaining browser coverage through websocket dual-browser invocation.
