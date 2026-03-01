---
# cerberus-cb0r
title: Update docs to match reorganized module structure and test strategy
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T19:42:50Z
parent: cerberus-whq9
---

Phase 5: Documentation and architecture alignment.

Goals:
- Reflect driver-first organization and test strategy after refactor.
- Keep naming guidance aligned with HTML spec, Phoenix, PhoenixTest, Playwright, and Capybara references.

## Todo
- [x] Update README and docs/architecture module references
- [x] Document driver-loop test pattern replacing harness usage
- [x] Document integration test placement in test/cerberus with CerberusTest.*
- [x] Run format and precommit

## Summary of Changes
- Updated README wording to keep public docs user-facing and aligned with session-first mode naming.
- Expanded docs/architecture with driver-first module map that reflects current static/live/browser file structure.
- Documented maintainer test strategy in docs/architecture: plain ExUnit driver loops and integration placement under test/cerberus/cerberus_test with CerberusTest modules.
- Ran mix format and source .envrc && mix precommit.
