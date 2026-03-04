---
# cerberus-f96e
title: Investigate bad scope in ev2 group_list_test
status: completed
type: bug
priority: normal
created_at: 2026-03-04T19:07:26Z
updated_at: 2026-03-04T19:10:57Z
---

Reproduce failing ev2 test at test/ev2_web/live/distro_live/group_list_test.exs:61 and trace where Cerberus scope value is sourced/mutated.

## Summary of Changes
- Reproduced the failure in ev2 at test/ev2_web/live/distro_live/group_list_test.exs:61.
- Identified the scope source: the test calls assert_has(session, css(a), ~lAll project membersi), which Cerberus interprets as scoped assert form (scope_locator plus locator), internally using within/3.
- Confirmed via Cerberus API dispatch in lib/cerberus.ex: the 3-arity assert_has overload routes locator_input third arg to scoped within assertion.
- The resolved scope selector in the error is therefore expected: within matched the first anchor element (Home link), then text assertion ran inside that scope and failed.
