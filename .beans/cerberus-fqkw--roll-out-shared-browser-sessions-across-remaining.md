---
# cerberus-fqkw
title: Roll out shared browser sessions across remaining unit suites
status: in-progress
type: task
priority: normal
created_at: 2026-03-03T10:30:33Z
updated_at: 2026-03-03T10:50:13Z
---

Apply shared browser-session reuse to remaining safe cross-driver unit-style tests to cut browser startup overhead.\n\nScope:\n- [x] Convert remaining safe cross-driver modules to shared browser session setup\n- [x] Keep isolation-sensitive modules unchanged (sandbox/multi-user semantics)\n- [x] Run format + focused impacted suites + precommit\n- [ ] Commit code + bean
