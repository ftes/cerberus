---
# cerberus-lxqz
title: Remove stale slow-suite instruction from AGENTS
status: scrapped
type: task
priority: normal
created_at: 2026-03-10T19:26:01Z
updated_at: 2026-03-10T19:26:16Z
---

Update AGENTS.md to remove the stale requirement to run mix test --only slow before each commit, since the suite no longer uses a separate slow lane. Keep the guidance aligned with the current unified test lane and commit the bean with the docs change.

## Reasons for Scrapping

No change was needed. `AGENTS.md` already says to run `MIX_ENV=test mix do format + precommit + test` before each commit and no longer contains the stale `test --only slow` instruction.
