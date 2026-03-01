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
- [ ] Continue splitting browser driver monolith (navigation/forms/assertions/expression builders)
- [ ] Split live/static modules where responsibilities are mixed
- [ ] Keep per-driver APIs coherent and discoverable
- [ ] Run format and precommit
