---
# cerberus-pzee
title: 'Live driver slice 1: one-shot text assertions via LiveViewTest'
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:22Z
updated_at: 2026-02-27T08:58:29Z
parent: cerberus-sfku
---

## Scope
Implement live driver integration using LiveViewTest for initial one-shot behavior.

## Details
- map session state to LiveView handle + watcher metadata.
- `assert_has/refute_has` use one-shot render + shared query semantics.
- `click` uses LiveViewTest event helpers and updates session state.

## Tests
- [ ] click increments counter live view.
- [ ] assert/refute text after live update.
- [ ] redirects and live redirects update `current_path`.

## Done When
- [ ] live driver passes conformance text specs in one-shot mode.
- [ ] no polling loop introduced in slice 1.
