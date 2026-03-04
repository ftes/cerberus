---
# cerberus-ipgn
title: Verify auto-scroll behavior before browser actions
status: completed
type: task
priority: normal
created_at: 2026-03-04T06:27:16Z
updated_at: 2026-03-04T06:29:02Z
---

Inspect Cerberus browser action implementation for pre-action scrolling and compare to Playwright/Cuprite behavior.

## Summary of Changes
- Verified Cerberus browser action helper currently performs actions via JS helper and element.click()/value mutation paths without explicit scrollIntoView before action.
- Verified Playwright docs state actionability includes scrolling element into view if needed before click/check and related actions.
- Verified Cuprite/Ferrum path calls before_click -> scrollIntoViewport and then node click uses mouse coordinates.
