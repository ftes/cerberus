---
# cerberus-cnsv
title: Mine open phoenix_test issues/PRs for new Cerberus bug beans
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:46:13Z
updated_at: 2026-02-27T21:48:49Z
parent: cerberus-zqpu
---

Scan open issues and pull requests in phoenix_test to find additional inconsistencies/bugs relevant to Cerberus parity.

## Todo
- [x] Gather current open phoenix_test issues and PRs with enough detail to assess behavior mismatches
- [x] Extract concrete bug candidates and group them by behavior
- [x] Create one Cerberus bug bean per bug/group with references and failing-test snippets where possible
- [x] Summarize created beans and source mapping for handoff

## Summary of Changes
Scanned current open issues and pull requests in `germsvel/phoenix_test` and created new Cerberus bug beans for uncovered parity/inconsistency candidates.

Created beans:
- cerberus-54ud: Assertion filter semantics (`#285`, `#286`, `#291`)
- cerberus-mz94: `fill_in` nested label-node matching (`#287`)
- cerberus-3q56: Checkbox array `name[]` check/uncheck behavior (`#269`, `#276`)
- cerberus-iy6e: Live form synchronization for dynamic/conditional inputs and `JS.dispatch("change")` (`#216`, `#300`, `#297`, `#203`, `#238`)
- cerberus-ng1c: `connect_params` dropped across live navigation (`#259`)
- cerberus-inh8: `click_button` multiline `data-confirm` lookup failure (`#205`)
- cerberus-yrpa: sub-100ms timeout granularity for async assertions (`#281`)

Each bean includes upstream links plus embedded repro/failing snippets (from issue text or PR test additions) and a concrete implementation checklist.
