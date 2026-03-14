---
# cerberus-v8my
title: Remove unused test bootstrap module
status: in-progress
type: task
created_at: 2026-03-14T17:14:51Z
updated_at: 2026-03-14T17:14:51Z
---

Delete the unused Cerberus.TestSupport.Bootstrap module now that test/test_helper.exs is the only active test boot path. Verify no references remain and rerun focused gates.
