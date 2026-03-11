---
# cerberus-omba
title: Fix force click wait for transiently disabled browser buttons
status: completed
type: bug
priority: normal
created_at: 2026-03-11T20:10:20Z
updated_at: 2026-03-11T20:14:36Z
---

Investigate CI failures in EV2 copy where Cerberus browser click with force: true hits a temporarily disabled confirm button before it enables.

- [x] inspect current browser click force semantics and reproduce the failing path
- [x] adjust Cerberus browser action behavior or regression coverage for forced click on temporarily disabled controls
- [x] run focused Cerberus and EV2 copy tests with random PORT
- [x] summarize changes and mark bean completed if all work is done

## Summary of Changes

Adjusted browser action retry semantics so force-click still retries transient field_disabled failures, added delayed-enabled browser regression coverage, extended the delayed actionability fixture with a button case, and updated ExDoc extras so the full precommit/docs gate passes.

Validation:
- PORT=4321 mix test test/cerberus/actionability_disabled_state_test.exs
- PORT=4322 mix test test/ev2_web/controllers/my_offer_controller_integration_cerberus_test.exs
- PORT=4323 MIX_ENV=test mix do format + precommit + test
