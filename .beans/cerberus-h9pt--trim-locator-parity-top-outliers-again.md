---
# cerberus-h9pt
title: Trim locator parity top outliers again
status: scrapped
type: task
priority: normal
created_at: 2026-03-09T15:45:08Z
updated_at: 2026-03-09T16:07:41Z
---

## Goal

Reduce runtime of the dominant locator parity tests without weakening the shared static/browser parity contract.

## Tasks

- [ ] Inspect the current locator parity support and identify the slowest parity groups
- [ ] Trim repeated setup or redundant cases while preserving parity coverage
- [ ] Re-run targeted locator parity tests and the unified full gate
- [ ] Summarize the updated top unified outliers

## Reasons for Scrapping

Splitting the locator parity corpus into smaller async modules reduced individual test durations but did not improve unified suite wall-clock time. The follow-up request shifted to code organization: keep one file/module and use describe blocks instead of multiple modules.
