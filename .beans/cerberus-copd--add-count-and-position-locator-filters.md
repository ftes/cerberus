---
# cerberus-copd
title: Add count and position locator filters
status: in-progress
type: feature
priority: normal
created_at: 2026-03-01T16:00:44Z
updated_at: 2026-03-01T20:28:21Z
blocked_by:
    - cerberus-1xnx
---

Support count/position matching constraints (count/min/max/between, first/last/nth/indexed selection) in locator APIs and driver implementations with parity tests.

## Prerequisite
- Complete cerberus-1xnx rich locator oracle corpus updates first; preserve and extend that corpus as this bean lands.


## Todo
- [x] Fix and finalize option validation for count/position filters
- [x] Wire count/position selection into static/live/html locator resolution
- [x] Wire count/position selection into browser locator resolution
- [x] Apply count constraints to assert_has/refute_has across static/live/browser
- [x] Expand Elixir-vs-JS locator oracle harness with extensive count/position parity cases
- [ ] Run format + focused tests + precommit and commit
