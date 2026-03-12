---
# cerberus-lemw
title: Investigate browser vs live actionability waits
status: completed
type: task
priority: normal
created_at: 2026-03-12T08:37:23Z
updated_at: 2026-03-12T08:40:43Z
---

Investigate whether Cerberus action functions wait for actionability consistently across browser and live drivers, and whether gaps are limited to click or affect other actions.

- [x] inspect browser action implementation and JS action performer
- [x] inspect live action implementation for comparison
- [x] run targeted tests or reproductions for browser and live
- [x] summarize whether gaps are click-only or broader

## Summary of Changes

Inspected the browser and live driver action paths, including the browser JS action helper. Ran the existing delayed-actionability suites and a disposable browser probe. The result is that live actions already wait for actionable candidates, browser actions already wait for locator resolution and retry disabled-state failures for all action ops, but browser does not retry general actionability failures like delayed visibility. That gap is browser-only and broader than click because all browser action ops share the same perform/retry path.
