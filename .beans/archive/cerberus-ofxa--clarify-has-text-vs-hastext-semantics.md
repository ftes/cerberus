---
# cerberus-ofxa
title: Clarify has_text vs has(text()) semantics
status: completed
type: task
priority: normal
created_at: 2026-03-06T09:24:28Z
updated_at: 2026-03-06T09:25:18Z
---

## Goal\n\nAnswer why has_text exists versus has(text()), using Playwright semantics as reference and mapping to Cerberus API design.\n\n## Todo\n\n- [x] Verify Playwright filter option semantics from official docs\n- [x] Compare has_text and has(text()) tradeoffs for Cerberus\n- [x] Provide recommendation for API surface\n

## Summary of Changes\n\n- Verified Playwright locator filter semantics from official docs, including has, hasNot, hasText, and hasNotText options.\n- Compared semantics of text filtering versus nested text locators for Cerberus design, focusing on candidate identity and matching behavior.\n- Prepared recommendation to keep has_text style filter support distinct from chained text locator composition semantics.\n
