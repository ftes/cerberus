---
# cerberus-uni0
title: Better option selected assertion handling in static/live snapshots
status: completed
type: bug
priority: normal
created_at: 2026-03-05T13:49:26Z
updated_at: 2026-03-05T14:16:18Z
---

Problem pattern: assert_has("select[name='x'] option[value='y'][selected]"). In Live/static render paths, selected state may come from form value/state and not always explicit selected attribute in HTML snapshots. Improve assertion matching to respect effective selected state.

## Summary of Changes
- Added selector fallback helper in core driver code for selected-option selector pattern against form_data state.
- Wired fallback into static and live locator assertion resolution, only when normal HTML selector match returns no candidates.
- Added shim compatibility regression tests covering selected option assertions after select action in static and live sessions.
- Verified with:
  - direnv exec . env PORT=4135 mix test test/cerberus/compat/phoenix_test_shim_behavior_test.exs
  - direnv exec . env PORT=4136 mix test test/cerberus/phoenix_test/assertions_test.exs test/cerberus/driver/html_test.exs
  - source .envrc && env PORT=4137 mix test test/cerberus/browser_test.exs
