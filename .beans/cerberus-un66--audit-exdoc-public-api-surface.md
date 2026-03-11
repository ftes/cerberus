---
# cerberus-un66
title: Audit ExDoc public API surface
status: completed
type: task
priority: normal
created_at: 2026-03-11T19:15:35Z
updated_at: 2026-03-11T19:17:02Z
---

Assess whether internal/support modules are appearing in public ExDoc and whether they should be hidden.

- [x] Inspect ExDoc configuration and module docs settings
- [x] Review public-facing modules/functions, including Cerberus.Session.with_scope
- [x] Summarize whether the public surface is too broad and recommend concrete changes

## Summary of Changes

- Audited ExDoc configuration in mix.exs and confirmed internal modules are primarily hidden via @moduledoc false rather than explicit docs filtering.
- Built ExDoc locally and verified the generated API index currently exposes Cerberus, Cerberus.Browser, Cerberus.Browser.Install, Cerberus.Browser.Native, Cerberus.Locator, Cerberus.Options, and Cerberus.Session.
- Reviewed source/docs usage and concluded Cerberus.Session and its with_scope/2 callback are internal protocol surface, Cerberus.Browser.Install is likely mix-task support rather than user API, Cerberus.Browser.Native is intentionally public because unwrap/2 documents it, and Cerberus.Options is borderline but currently serves as the docs target for public option/typespec links.
