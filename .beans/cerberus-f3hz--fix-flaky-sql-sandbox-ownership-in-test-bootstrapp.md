---
# cerberus-f3hz
title: Fix flaky SQL sandbox ownership in test bootstrapping
status: in-progress
type: bug
priority: normal
created_at: 2026-03-03T16:57:22Z
updated_at: 2026-03-03T17:05:33Z
---

Reproduce and fix intermittent DBConnection.OwnershipError in Cerberus.SQLSandboxBehaviorTest phoenix lane by restoring deterministic sandbox checkout/allow semantics in shared test support.

## Progress\n- Reproduced flaky OwnershipError in SQL sandbox behavior tests after compile.\n- Simplified sql_sandbox_user_agent repo checkout flow in lib/cerberus.ex to align with Phoenix.Ecto concurrent browser guidance: maintain one start_owner pid per repo per test process and reuse it; emit metadata_for(owner_pid) for single-repo and metadata_for(self()) for multi-repo.\n- Removed brittle fallback logic that silently tolerated already-allowed ownership states.\n- Blocked from executing MIX_ENV=test validations by unrelated local config/test.exs regression (System.get_env defaults passed as integers), which crashes test config evaluation before ExUnit starts.

- Fixed compile regression in lib/cerberus.ex by removing Process.alive?/1 from guard and moving pid liveness check into function body.
