---
# cerberus-go8p
title: Set websocket default browsers to all and move migration verification to final CI test step
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:19:54Z
updated_at: 2026-02-28T20:21:11Z
---

## Goal
Make mix test.websocket default to provisioning both chrome and firefox, and ensure migration verification remains separate and is the final test step in CI.

## Todo
- [x] Change websocket browser default from chrome to all
- [x] Update docs to match default behavior
- [x] Reorder CI test steps so migration verification runs last
- [x] Validate workflow/task behavior and summarize

## Summary of Changes
- Changed mix task defaults so `mix test.websocket` now defaults to browser set `all` (chrome + firefox).
- Updated task docs/help text to reflect default `all` for `--browsers` and `CERBERUS_REMOTE_SELENIUM_BROWSERS`.
- Updated README and getting-started docs to state websocket default is `all`.
- Reordered CI test stages so migration verification remains separate and runs last.

## Validation
- mix format
- mix test.websocket --only remote_webdriver (without `--browsers`) to verify default now provisions chrome+firefox
