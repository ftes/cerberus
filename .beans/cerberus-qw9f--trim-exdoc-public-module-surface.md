---
# cerberus-qw9f
title: Trim ExDoc public module surface
status: completed
type: task
priority: normal
created_at: 2026-03-11T19:19:10Z
updated_at: 2026-03-11T19:21:53Z
---

Hide internal/support modules from public ExDoc while keeping Cerberus.Options visible.

- [x] Hide Cerberus.Session from ExDoc
- [x] Hide Cerberus.Browser.Install from ExDoc
- [x] Regenerate docs and verify exposed module list
- [x] Run targeted tests and format

## Summary of Changes

- Hid Cerberus.Session and Cerberus.Browser.Install from ExDoc by marking both modules with @moduledoc false.
- Added a public opaque Cerberus.session_handle() type and updated public specs/docs to reference that type instead of the hidden Cerberus.Session protocol.
- Regenerated ExDoc in a fresh output directory to verify the public module list now drops Cerberus.Session and Cerberus.Browser.Install while keeping Cerberus.Options visible.
- Ran mix format and targeted tests with sourced env vars and a random PORT.
