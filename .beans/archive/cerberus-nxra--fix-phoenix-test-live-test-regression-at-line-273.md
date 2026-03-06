---
# cerberus-nxra
title: Fix phoenix_test live_test regression at line 273
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:22:55Z
updated_at: 2026-03-05T14:25:38Z
---

Reproduce and fix failing test at test/cerberus/phoenix_test/live_test.exs:273 and ensure precommit passes.

## Summary of Changes
- Reproduced failing test at test/cerberus/phoenix_test/live_test.exs:273 where LiveView click raised raw ArgumentError instead of translated AssertionError.
- Updated live button click handling in lib/cerberus/driver/live.ex:
  - detect disabled live buttons before click execution and return standard no-button-matched error path
  - catch LiveView ArgumentError during render_click and translate to standard click assertion error path
  - threaded click kind through click_live_button clauses to keep reason text consistent
- Verified fixed regressions:
  - source .envrc && env PORT=4142 mix test test/cerberus/phoenix_test/live_test.exs:273
  - source .envrc && env PORT=4145 mix test test/cerberus/phoenix_test/live_test.exs test/cerberus/phoenix_test_playwright/upstream/live_test.exs
- Precommit status:
  - source .envrc && env PORT=4146 mix precommit still fails due unrelated existing Credo findings in other files, not from this live click fix.
