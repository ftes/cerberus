---
# cerberus-dkhr
title: Fix browser static->live link context loss
status: todo
type: bug
created_at: 2026-03-05T14:53:52Z
updated_at: 2026-03-05T14:53:52Z
---

Investigate and fix BiDi context loss when clicking static links into LiveView in browser lane. Repro: test/cerberus/phoenix_test_playwright/upstream/static_test.exs "handles navigation to a LiveView". Current workaround is skipped test.
