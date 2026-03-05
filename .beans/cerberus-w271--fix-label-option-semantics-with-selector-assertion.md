---
# cerberus-w271
title: Fix label option semantics with selector assertions
status: completed
type: bug
priority: normal
created_at: 2026-03-05T14:09:46Z
updated_at: 2026-03-05T14:16:18Z
---

Add regression tests derived from EV2 shim skips for assert_has with selector + label filters (e.g. input[disabled] label: Foo) and make core assertion matching label-to-control aware instead of same-node label text matching.

## Summary of Changes
- Added shim compatibility regression test for selector plus label assertions against form controls on static and live pages.
- Updated HTML locator label matching so label locators resolve associated control labels for input, textarea, and select candidates.
- Updated browser locator assertion helper script to apply label matching to form controls via label-for and wrapping-label lookup, aligning with static/live semantics.
- Verified with:
  - direnv exec . env PORT=4135 mix test test/cerberus/compat/phoenix_test_shim_behavior_test.exs
  - direnv exec . env PORT=4136 mix test test/cerberus/phoenix_test/assertions_test.exs test/cerberus/driver/html_test.exs
  - source .envrc && env PORT=4137 mix test test/cerberus/browser_test.exs
