---
# cerberus-y0uw
title: Delegate live open_browser to LiveViewTest
status: completed
type: feature
priority: normal
created_at: 2026-03-04T19:05:06Z
updated_at: 2026-03-04T19:06:24Z
---

Update Cerberus live driver open_browser to delegate to Phoenix.LiveViewTest.open_browser when a LiveView is active, preserving head/static asset behavior. Add tests that verify stylesheet path is present in live open_browser snapshots.

## Summary of Changes
- Updated Cerberus live driver open_browser to delegate to Phoenix.LiveViewTest.open_browser when a live view is present.
- Kept the existing Cerberus snapshot fallback for non-live-view live-session states.
- Restored fixture LiveView layout stylesheet link so head/static asset behavior is exercised in tests.
- Added a live-specific open_browser test that asserts the stylesheet href is rewritten to a local file:// path pointing at priv/static/assets/app.css.
- Verified with targeted tests: open_browser behavior suite and core open_browser tests in cerberus_test.
