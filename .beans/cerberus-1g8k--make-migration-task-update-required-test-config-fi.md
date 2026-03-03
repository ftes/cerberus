---
# cerberus-1g8k
title: Make migration task update required test config files
status: in-progress
type: task
created_at: 2026-03-03T16:01:12Z
updated_at: 2026-03-03T16:01:12Z
---

## Goal
Make mix cerberus.migrate_phoenix_test a one-stop migration step by updating required setup in config/test.exs and test/test_helper.exs.

## Todo
- [ ] Identify required Cerberus config/test helper bootstrap lines
- [ ] Implement migration task rewrites for config/test.exs and test/test_helper.exs
- [ ] Add/extend migration task tests for config/test helper updates
- [ ] Run format and targeted tests
