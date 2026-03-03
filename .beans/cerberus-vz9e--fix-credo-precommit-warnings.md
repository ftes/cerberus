---
# cerberus-vz9e
title: Fix Credo precommit warnings
status: in-progress
type: task
created_at: 2026-03-03T16:37:39Z
updated_at: 2026-03-03T16:37:39Z
---

Refactor the three Credo findings currently failing precommit: complexity in canonicalize_assertion_scope_args/2 and nested depth in Cerberus.Browser.Install.install/1 and ensure_stable_symlinks/3, then re-run precommit.
