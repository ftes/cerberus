---
# cerberus-c4yc
title: Investigate EV2 toast assertion reliability under Cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-10T15:19:16Z
updated_at: 2026-03-10T15:23:52Z
---

Find out why EV2 toast assertions that were stable in PhoenixTest/Playwright are unreliable in Cerberus. Determine whether failures are caused by checking too early during fade-in, too late after auto-close, visibility semantics differences, or another cause.
- [x] inspect EV2 toast implementation and timing semantics
- [x] inspect Playwright vs Cerberus browser assertion behavior relevant to toast visibility
- [x] run or inspect a concrete migrated EV2 example and classify the failure mode
- [x] summarize conclusions and recommended fix direction

## Summary of Changes

Findings from EV2 toast investigation:
- Normal EV2 toasts do not fade in. They render immediately in Components.Alert.toast/1 and auto-close after 5000ms via assets/js/toast.js.
- The hide transition is only used on dismissal. Visibility mismatch during fade-in is not the issue.
- A direct Cerberus browser assertion on the preserved project-create flow passes today with timeout 4000ms.
- A timing probe on the same flow showed:
  - immediately after the submit click: no toast yet
  - at +1s: toast present and visible
  - at +4s: toast still present and visible
  - at +6s: toast gone

Conclusion:
- For browser tests, the main failure mode is not Cerberus checking too early before fade-in, and not a generic inability to catch the toast before auto-close.
- The real issue in prior migrations was test shape: when the Cerberus copy inserted assert_path or other follow-up work before checking the toast, that changed what was being asserted and sometimes made the toast check irrelevant or late.
- For non-browser live tests, the issue is different: Cerberus live actions often operate on the settled post-transition state rather than the earlier flash snapshot PhoenixTest could assert against.

Recommended fix direction:
- Browser: if the original Playwright test asserted the toast directly after the action, keep the toast assertion directly after the action in the Cerberus copy.
- Browser: do not insert assert_path before the toast unless path is the intended stronger replacement.
- Live/non-browser: prefer path/persisted-state/side-effect assertions over transient toast assertions unless we intentionally change live flash semantics.
