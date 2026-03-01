---
# cerberus-u8js
title: Hide internal driver and semantics modules from ExDoc public surface
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:13Z
updated_at: 2026-02-28T16:13:43Z
---

Finding follow-up: Cerberus currently documents internal modules as public API in ExDoc.

## Scope
- Mark non-public driver/semantics modules with @moduledoc false (or explicitly exclude from docs)
- Keep user-facing modules documented
- Verify docs output only contains intended public contract

## Acceptance
- Internal implementation modules are no longer presented as supported API docs
- README/guides remain accurate

## Summary of Changes

- Marked internal driver and semantics modules as hidden from ExDoc (@moduledoc false) across Cerberus.Driver, Cerberus.Driver.Static, Cerberus.Driver.Live, Cerberus.Driver.Browser, Cerberus.Driver.Html, and Cerberus.Driver.LiveViewHtml.
- Kept user-facing modules (Cerberus, Cerberus.Browser, Cerberus.Session, Cerberus.Options, Cerberus.Locator) documented to preserve public docs and avoid broken type references.
- Hid Cerberus.Query from ExDoc as an internal semantic helper.
- Updated architecture guide wording to describe semantic layers without linking hidden modules.
- Verified docs generation with mix docs --warnings-as-errors --formatter html.
