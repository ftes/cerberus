---
# cerberus-atqb
title: Investigate flaky browser assert_path on async redirect
status: in-progress
type: bug
created_at: 2026-03-01T20:46:05Z
updated_at: 2026-03-01T20:46:05Z
---

Investigate intermittent failure in Cerberus.BrowserTimeoutAssertionsTest where assert_path reports path/query mismatch despite matching path text. Determine browser-specific behavior and fix race in browser path assertion pipeline if needed.
