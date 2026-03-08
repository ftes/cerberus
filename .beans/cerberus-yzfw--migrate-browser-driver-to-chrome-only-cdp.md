---
# cerberus-yzfw
title: Migrate browser driver to Chrome-only CDP
status: completed
type: feature
priority: normal
created_at: 2026-03-08T20:46:34Z
updated_at: 2026-03-08T21:52:57Z
---

## Scope

- [x] Replace the browser driver transport and lifecycle stack with Chrome-only CDP.
- [x] Remove Firefox support and BiDi assumptions from the active browser lane.
- [x] Update browser docs and focused tests for the Chrome-only CDP driver.
- [x] Verify Cerberus browser suites, precommit, and the stable EV2 browser comparison row.

## Notes

- Clean cut: no backward-compatibility shim for Firefox or BiDi browser sessions.
- Keep WebDriver only as the managed Chrome startup/session bootstrap if still useful.
- Target end state is a Chrome-only CDP browser driver, not a hybrid driver.

## Summary of Changes

- Replaced the active browser lane with a Chrome-only CDP-backed driver path and removed Firefox from the public session/options surface.
- Kept ChromeDriver only for managed Chrome startup/bootstrap, then attached CDP page processes per tab for evaluate, actions, dialogs, reload, and readiness-related operations.
- Fixed popup init-script attachment, readiness timeout fallback classification, slow-mo propagation, and dialog unblock handling on the new CDP path.
- Updated browser docs and focused tests for the Chrome-only policy, and added a raw Chrome BiDi vs CDP benchmark harness/test.
- Verified Cerberus with mix precommit, mix test, and mix test --only slow.
- Stable EV2 browser comparison row on March 8, 2026: Playwright project_form_feature_test.exs finished in 5.9s; Cerberus project_form_feature_cerberus_test.exs finished in 21.6s, so the driver is functionally green but still not near Playwright parity.
