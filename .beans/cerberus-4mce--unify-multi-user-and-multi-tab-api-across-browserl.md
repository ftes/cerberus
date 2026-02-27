---
# cerberus-4mce
title: Unify multi-user and multi-tab API across browser/live/static drivers
status: todo
type: task
created_at: 2026-02-27T19:43:01Z
updated_at: 2026-02-27T19:43:01Z
parent: cerberus-sfku
---

## Scope
Design and implement a single public Cerberus API for multi-user and multi-tab workflows that can run unchanged across browser and live/static drivers.

## Goals
- Introduce a common user+tab session model in public API.
- Map browser behavior to userContext+browsingContext.
- Map live/static behavior to shared cookie/session jar per user and per-tab session instances.
- Keep tests mode-switchable between browser and live/static.

## Done When
- [ ] Public API exists for opening/switching/closing users and tabs.
- [ ] Browser driver implements the API with tab semantics.
- [ ] Live/static drivers implement compatible semantics.
- [ ] Cross-driver conformance tests validate same scenario in browser and live/static.
- [ ] Docs explain semantic differences (cookies/storage/events).
