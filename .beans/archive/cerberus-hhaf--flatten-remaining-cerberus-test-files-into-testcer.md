---
# cerberus-hhaf
title: Flatten remaining cerberus_test files into test/cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-01T20:41:11Z
updated_at: 2026-03-01T20:44:34Z
---

Move all remaining tests from test/cerberus/cerberus_test to test/cerberus root, update test modules to match flat namespace, and remove the cerberus_test directory.


## Todo
- [x] Move all test files from test/cerberus/cerberus_test to test/cerberus
- [x] Rename test modules from CerberusTest.* to Cerberus.* for flat namespace consistency
- [x] Remove empty test/cerberus/cerberus_test directory
- [x] Run format and test suite for moved files
- [ ] Commit code + bean file
