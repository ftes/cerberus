---
# cerberus-tnaj
title: Handle remaining skipped tests
status: completed
type: task
priority: normal
created_at: 2026-03-09T16:56:51Z
updated_at: 2026-03-09T17:01:54Z
---

Inspect the currently skipped Cerberus tests, decide which ones should be re-enabled, implement the needed fixes or clean cuts, and verify the full test suite.

## Summary of Changes

Removed the remaining skip tags by fixing browser active-form submit parity for no-button live forms, unskipping the stale browser data-method live test, and deleting two obsolete dialog-action tests that no longer matched the supported browser contract. Verified with targeted files and the full format + precommit + test gate; there are now no remaining skipped tests under test/.
