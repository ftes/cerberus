---
# cerberus-j5np
title: Resolve test browser lane from config
status: in-progress
type: task
created_at: 2026-03-14T17:16:18Z
updated_at: 2026-03-14T17:16:18Z
---

Set :cerberus, :browser browser_name from CERBERUS_BROWSER_NAME in config/test.exs so browser-lane tests read the effective configured lane instead of reaching into env. Update skip tags and rerun focused Chrome/Firefox checks.
