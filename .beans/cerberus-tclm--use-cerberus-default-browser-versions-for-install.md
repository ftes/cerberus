---
# cerberus-tclm
title: Use Cerberus default browser versions for install tasks
status: completed
type: task
priority: normal
created_at: 2026-03-12T09:16:47Z
updated_at: 2026-03-12T09:19:12Z
---

Make browser install tasks prefer explicit flags, then explicit env vars, then Cerberus-provided default pinned versions instead of latest stable. Update focused tests and docs.

## Summary of Changes

- added Cerberus-pinned default browser versions in `Cerberus.Browser.Install`
- changed `mix cerberus.install.chrome` and `mix cerberus.install.firefox` to resolve versions as: explicit flag, then matching env var, then Cerberus default pinned version
- updated focused install-task tests to assert the new precedence behavior
- updated install docs and stale explicit-version examples to match the pinned defaults
