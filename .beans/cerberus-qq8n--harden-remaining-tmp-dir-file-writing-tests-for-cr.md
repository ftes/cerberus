---
# cerberus-qq8n
title: Harden remaining tmp_dir file-writing tests for cross-process runs
status: draft
type: task
priority: normal
created_at: 2026-03-01T20:12:51Z
updated_at: 2026-03-02T05:37:19Z
---

Audit all tests using @tag :tmp_dir and deterministic artifact names/paths (logs, fixture files, directories). Move collision-prone writes to per-run unique paths outside deterministic ExUnit tmp roots, or introduce helper utilities to isolate paths across concurrent mix test processes.


## Planning Note
- Marked optional/unplanned per user direction; defer unless cross-process tmp_dir failures reappear.
