---
# cerberus-dp08
title: Trim EV2 project form Cerberus browser runtime
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T21:34:52Z
updated_at: 2026-03-10T21:52:44Z
---

Follow-up from the EV2 browser-vs-original comparison. Re-measure the preserved project_form_feature original and Cerberus copy, inspect slowest rows, profile the Cerberus browser path on current HEAD, and implement the next targeted speedup if justified.

## Plan
- [ ] Re-measure preserved project_form_feature original vs Cerberus copy on current HEAD
- [x] Collect current browser slowest/profile data for the Cerberus copy
- [ ] Identify the dominant browser overhead versus Playwright
- [ ] Implement one targeted speedup if justified
- [ ] Re-run focused downstream comparison and Cerberus quality gates

## Findings so far
- Current preserved pair on HEAD: original 5.4s, Cerberus 8.8s for the whole file.
- With CDP evaluate enabled, resolver JS is no longer the main cost in this row.
- Full-file profile shows the largest browser costs are fixed session and visit work, not login field interactions.
- Main buckets in the Cerberus copy: browser.createUserContext 1325.9ms total across 3 tests, driver_session new_session 1079-1281ms per test, visit 560-707ms per test, await_ready 393-422ms per test.
- Actual login interactions are cheap by comparison: fill_in 16-20ms per test, click about 83-104ms per test, assert_path under 90ms per test.
- Attempted one shared browser session per module, but the EV2 file uses per-test Mox setup and browser requests then lost the right expectation owner. That path is not worth the added harness complexity for this file.
