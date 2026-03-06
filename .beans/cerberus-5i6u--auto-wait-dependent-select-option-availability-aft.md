---
# cerberus-5i6u
title: Auto-wait dependent select option availability after LiveView updates
status: todo
type: bug
priority: normal
created_at: 2026-03-06T21:08:47Z
updated_at: 2026-03-06T21:14:12Z
blocked_by:
    - cerberus-84zg
---

Select actions currently wait for locator resolution, but not for requested option availability after dependent LiveView updates. Add browser and live action semantics that wait for requested options to appear and become enabled before failing, using the action timeout budget. Keep static immediate. Add regression coverage for parent-select then child-select flows where the child select is present but its options are repopulated asynchronously.

## Docs Follow-up\n\nIf this bean lands as intended, simplify MIGRATE_FROM_PHOENIX_TEST.md by removing or narrowing the temporary guidance about waiting for dependent select options to repopulate before selecting. The migration guide should describe the manual workaround only while this gap still exists.
