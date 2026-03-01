---
# cerberus-8z0n
title: Add docs-impact check guidance to AGENTS
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:10:14Z
updated_at: 2026-02-28T07:10:33Z
---

Add a short AGENTS.md rule requiring a docs impact check at the end of implementation, before mix format and mix precommit; emphasize README/moduledocs updates for public behavior changes.

## Summary of Changes
Added a short Docs check (final step) section to AGENTS.md.
It requires a docs impact check at the end of implementation, right before mix format and mix precommit, and calls out updating README.md, relevant guides, and moduledocs when public API, behavior, or examples change.
