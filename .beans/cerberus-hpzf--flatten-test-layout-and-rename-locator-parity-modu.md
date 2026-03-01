---
# cerberus-hpzf
title: Flatten test layout and rename locator parity module
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T20:33:58Z
updated_at: 2026-03-01T20:36:05Z
---

Move tests out of test/cerberus/core into test/cerberus root and rename locator oracle harness to Cerberus.LocatorParityTest under test/cerberus. Keep module/file naming aligned with module under test and avoid conflicts with Cerberus.LocatorTest.


## Todo
- [x] Rename locator oracle harness file/module to LocatorParityTest in test/cerberus
- [x] Move core tests from test/cerberus/core into test/cerberus
- [x] Remove now-empty test/cerberus/core directory
- [x] Run format and focused tests
- [ ] Commit code + bean file
