---
# cerberus-cye9
title: Trim browser multi-session behavior test runtime
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:23:43Z
updated_at: 2026-03-09T15:34:07Z
---

## Goal

Reduce runtime of the browser multi-session behavior module without weakening its tab/session isolation contract.

## Tasks

- [x] Profile the current module to identify startup versus assertion cost
- [x] Remove redundant setup or assertions while preserving the multi-session guarantees
- [x] Re-run targeted tests and the unified full gate
- [x] Summarize the updated top regular outliers

## Summary of Changes

Profile data showed browser_multi_session_behavior_test was dominated by fresh browser session startup. The module now creates one primary and one isolated browser session in setup_all and resets them by revisiting the needed routes inside each test. That kept the tab/session isolation contract intact while dropping the two browser rows to roughly 0.72s and 0.42s. Verified with targeted reruns and the unified mix do format + precommit + test gate.
