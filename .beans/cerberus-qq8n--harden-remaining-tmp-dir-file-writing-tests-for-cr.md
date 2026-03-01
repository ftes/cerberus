---
# cerberus-qq8n
title: Harden remaining tmp_dir file-writing tests for cross-process runs
status: todo
type: task
created_at: 2026-03-01T20:12:51Z
updated_at: 2026-03-01T20:12:51Z
---

Audit all tests using @tag :tmp_dir and deterministic artifact names/paths (logs, fixture files, directories). Move collision-prone writes to per-run unique paths outside deterministic ExUnit tmp roots, or introduce helper utilities to isolate paths across concurrent mix test processes.
