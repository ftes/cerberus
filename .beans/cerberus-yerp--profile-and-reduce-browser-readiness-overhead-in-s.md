---
# cerberus-yerp
title: Profile and reduce browser readiness overhead in slow EV2 Cerberus tests
status: completed
type: bug
priority: normal
created_at: 2026-03-08T07:26:57Z
updated_at: 2026-03-08T07:35:40Z
---

## Scope

- [x] Profile the expensive browser readiness and action wait paths more finely.
- [x] Identify the dominant bottleneck causing the slow EV2 Cerberus browser samples.
- [x] Implement the smallest safe fix in Cerberus.
- [x] Verify the fix with targeted Cerberus tests and profiled EV2 comparisons.
- [x] Document the findings in the bean summary.

## Summary of Changes

- Added a regression in /Users/ftes/src/cerberus/test/cerberus/browser_action_settle_behavior_test.exs covering live label clicks that can settle inline without a full await_ready round trip.
- Changed /Users/ftes/src/cerberus/lib/cerberus/driver/browser/action_helpers.ex so label-backed click actions use the inline settle path rather than always forcing await_ready.
- Fixed a larger hot-path bug in /Users/ftes/src/cerberus/lib/cerberus/driver/browser/evaluate.ex: Evaluate.with_dialog_unblock had been busy-spinning while waiting for script.evaluate, repeatedly polling without sleeping. It now actually waits up to the poll interval before rechecking dialog state.

## Findings

- The first profiling pass showed browser time dominated by evaluate_with_timeout, click, and await_ready, not by in-page JS execution.
- The label-click change reduced unnecessary await_ready calls in project_form_feature_cerberus_test, but the large win came from the evaluate loop fix.
- After the evaluate loop fix, the profiled EV2 browser sample /Users/ftes/src/ev2-copy/test/features/project_form_feature_cerberus_test.exs dropped from about 23.9s profiled to 10.9s profiled.
- In that same sample, browser_wait evaluate_with_timeout collapsed from roughly 2.1s to 4.2s per test down to roughly 0.88s to 0.98s per test, and browser click time dropped from roughly 1.3s to 2.4s per test down to roughly 0.56s to 0.74s per test.
- A clean non-profiled rerun of /Users/ftes/src/ev2-copy/test/features/project_form_feature_cerberus_test.exs finished in 9.9s test time, versus the earlier 19.2s comparison run.
- Follow-up reruns of /Users/ftes/src/ev2-copy/test/features/register_and_accept_offer_cerberus_test.exs exposed an existing browser visibility/startup flake unrelated to the evaluate-loop optimization: one Chrome startup failure and repeated check visibility failures on the I verify control.
