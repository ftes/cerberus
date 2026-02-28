---
# cerberus-z239
title: Design CI browser matrix workflow and helper tasks
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:40:53Z
updated_at: 2026-02-28T08:44:19Z
parent: cerberus-ykr0
---

Design a practical CI workflow for Cerberus browser runs (binary/tool provisioning, matrix execution, and runtime constraints), and add any missing helper mix tasks/scripts/docs needed for deterministic runs.

## Summary of Changes

- Added a CI browser conformance matrix job (`chrome` + `firefox`) in `.github/workflows/ci.yml`.
- Added deterministic Firefox runtime setup in CI using `browser-actions/setup-firefox` + pinned GeckoDriver (`0.36.0`).
- Added Firefox BiDi readiness helper script: `bin/check_gecko_bidi_ready.sh`.
- Kept existing Chrome provisioning flow and added per-lane `CERBERUS_BROWSER_MATRIX` wiring for isolated browser conformance execution.
- Updated README with Firefox readiness helper and matrix run guidance.
- Verified local readiness helper and full `mix precommit` pass with Chrome + Firefox env vars.
