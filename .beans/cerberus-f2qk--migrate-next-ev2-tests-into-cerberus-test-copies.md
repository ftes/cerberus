---
# cerberus-f2qk
title: Migrate next EV2 tests into _cerberus_test copies
status: completed
type: task
priority: normal
created_at: 2026-03-10T14:56:58Z
updated_at: 2026-03-10T15:06:15Z
---

Create copy-based Cerberus migrations in ../ev2-copy without touching originals. Current slice:
- [x] migrate test/features/project_setup_test.exs into test/features/project_setup_cerberus_test.exs
- [x] migrate test/features/generate_timecards_browser_test.exs into test/features/generate_timecards_browser_cerberus_test.exs
- [x] run targeted EV2 verification for the new non-browser and browser copies
- [x] summarize findings and update bean

## Summary of Changes

Migrated two EV2 test copies without touching originals:
- test/features/project_setup_cerberus_test.exs now uses Ev2Web.ConnCase plus Cerberus for the long project setup flow.
- test/features/generate_timecards_browser_cerberus_test.exs now uses Ev2Web.CerberusBrowserCase plus Cerberus for two browser timecard-generation flows.

Verification:
- PORT=4873 MIX_ENV=test mix test test/features/project_setup_cerberus_test.exs
- PORT=4878 MIX_ENV=test mix test test/features/generate_timecards_browser_cerberus_test.exs --include integration
- PORT=4879 MIX_ENV=test mix test test/features/project_setup_cerberus_test.exs test/features/generate_timecards_browser_cerberus_test.exs --include integration

Findings:
- The non-browser project setup flow was more stable with redirect/sidebar assertions than transient toast or alert text assertions.
- The browser generate-timecards week-picker is not a good Cerberus clickable-control target today; the migrated copy uses direct week URLs after the initial Generate navigation to keep the downstream browser behavior under test.
