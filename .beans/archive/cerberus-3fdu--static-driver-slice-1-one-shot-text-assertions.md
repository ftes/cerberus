---
# cerberus-3fdu
title: 'Static driver slice 1: one-shot text assertions'
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:16Z
updated_at: 2026-02-27T08:58:25Z
parent: cerberus-sfku
---

## Scope
Implement static driver support for `visit`, `assert_has`, `refute_has`, and simple `click`.

## Details
- reuse parsed HTML operations from existing PhoenixTest-style helpers where possible.
- apply shared text matching semantics from `Cerberus.Query`.

## Tests
- [x] assert text on static route.
- [ ] refute text on static route.
- [ ] click link updates path/page and supports follow redirect.

## Done When
- [ ] static driver passes conformance text specs in one-shot mode.
