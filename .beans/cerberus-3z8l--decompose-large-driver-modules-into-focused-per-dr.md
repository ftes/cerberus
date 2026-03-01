---
# cerberus-3z8l
title: Decompose large driver modules into focused per-driver components
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T19:42:32Z
parent: cerberus-whq9
---

Phase 2: Split oversized driver modules while keeping driver ownership clear.

Goals:
- Break browser/live/static drivers into focused modules by responsibility.
- Avoid introducing cross-driver abstractions unless repeated and stable.

## Todo
- [x] Extract browser option/context normalization into `Cerberus.Driver.Browser.Config`
- [x] Extract static form-state and submit payload logic into `Cerberus.Driver.Static.FormData`
- [x] Extract live form-state, payload encoding, and target path helpers into `Cerberus.Driver.Live.FormData`
- [x] Extract browser assertion/path/html expression builders into `Cerberus.Driver.Browser.Expressions`
- [x] Extract browser snapshot expression into `Cerberus.Driver.Browser.Expressions`
- [x] Extract browser DOM discovery expressions (`clickables`, `form_fields`, `file_fields`) into `Cerberus.Driver.Browser.Expressions`
- [x] Extract browser action expressions (`upload_field`, `field_set`, `select_set`, `checkbox_set`, `radio_set`, `button_click`) into `Cerberus.Driver.Browser.Expressions`
- [x] Stop further browser micro-splitting for now (intentionally scoped out to avoid over-decomposition)
- [x] Stop additional live/static micro-splitting for now (current boundaries are sufficient)
- [x] Keep per-driver APIs coherent and discoverable
- [x] Run format and precommit for completed decomposition slices

## Summary of Changes
- Extracted durable high-value boundaries only: `Browser.Config`, `Browser.Expressions`, `Live.FormData`, and `Static.FormData`.
- Kept per-driver orchestration in place to avoid over-fragmenting control flow.
- Intentionally stopped deeper micro-decomposition (utility-level slicing) to preserve readability and debugging ergonomics.
