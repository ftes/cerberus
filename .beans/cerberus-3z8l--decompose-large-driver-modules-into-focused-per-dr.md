---
# cerberus-3z8l
title: Decompose large driver modules into focused per-driver components
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T19:03:22Z
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
- [ ] Continue splitting browser driver monolith (navigation/forms/assertions/expression builders)
- [ ] Split remaining live/static responsibilities into focused modules
- [ ] Keep per-driver APIs coherent and discoverable
- [x] Run format and precommit for completed decomposition slices
