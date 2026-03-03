---
# cerberus-vz9e
title: Fix Credo precommit warnings
status: completed
type: task
priority: normal
created_at: 2026-03-03T16:37:39Z
updated_at: 2026-03-03T17:19:10Z
---

Refactor the three Credo findings currently failing precommit: complexity in canonicalize_assertion_scope_args/2 and nested depth in Cerberus.Browser.Install.install/1 and ensure_stable_symlinks/3, then re-run precommit.

## Summary of Changes
- Refactored Credo-flagged functions in lib/mix/tasks/cerberus.migrate_phoenix_test.ex and lib/cerberus/browser/install.ex to reduce complexity/nesting.
- Fixed follow-up style and Dialyzer findings surfaced during precommit.
- Precommit checks now pass for this workspace state.
