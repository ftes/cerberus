---
# cerberus-i3z7
title: Tighten toast guidance in migration notes
status: completed
type: task
priority: normal
created_at: 2026-03-11T08:10:46Z
updated_at: 2026-03-11T08:10:59Z
---

Replace stale blanket wording about toast assertions in MIGRATE_FROM_PHOENIX_TEST.md with a precise split: browser toasts are generally fine when asserted immediately; live/non-browser flash/toast assertions are weaker because Cerberus may observe a later settled snapshot.

## Summary of Changes

Updated MIGRATE_FROM_PHOENIX_TEST.md to replace the stale blanket toast guidance with a precise split: browser toast assertions are generally reliable when asserted immediately after the triggering action, while live/non-browser toast assertions remain weaker because Cerberus may observe a later settled LiveView snapshot than PhoenixTest did.
