---
# cerberus-827a
title: Refresh local Chrome + ChromeDriver via bin script
status: completed
type: task
priority: normal
created_at: 2026-03-02T06:55:55Z
updated_at: 2026-03-02T06:57:05Z
---

## Problem\nLocal browser tests fail before execution due to Chrome/ChromeDriver mismatch.\n\n## TODO\n- [x] Inspect bin/chrome.sh behavior\n- [x] Run bin/chrome.sh to install/update Chrome + ChromeDriver\n- [x] Verify installed versions\n- [x] Re-run a browser startup smoke check\n- [x] Add summary of changes

## Summary of Changes\n- Ran bin/chrome.sh which installed Chrome for Testing 146.0.7680.31 and matching ChromeDriver 146.0.7680.31 under tmp/.\n- Verified both binaries report matching versions.\n- Re-ran browser startup smoke test (form_actions_test.exs:7) successfully.\n- Re-ran targeted browser suite and confirmed 49 tests passing.
