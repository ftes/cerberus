---
# cerberus-8935
title: Firefox support and cross-browser harness matrix
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:07:18Z
updated_at: 2026-02-28T08:36:41Z
parent: cerberus-ykr0
---

Add Firefox support and include it in conformance/harness browser runs alongside existing supported browsers.

## Notes
- Public API target: support `session(:chrome)` and `session(:firefox)`.
- `session(:browser)` should remain supported and default to Chrome.

## Summary of Changes

- Added explicit browser-target APIs: `session(:chrome)` and `session(:firefox)` while keeping `session(:browser)` as the default browser entrypoint.
- Extended browser runtime capability generation for both Chrome and Firefox (`goog:chromeOptions` and `moz:firefoxOptions`) with browser-specific managed/remote behavior.
- Added runtime browser selection (`browser_name`) and mixed-runtime protection so a single VM run cannot silently mix incompatible browser runtimes.
- Added harness browser-matrix expansion support (`browser_matrix`) so conformance runs can expand `:browser` into `:chrome`/`:firefox` targets.
- Added tests for runtime browser selection/capabilities and harness matrix behavior; retained compatibility for existing BiDi timeout probe tests.
- Updated README/docs to describe explicit browser targets and Firefox experimental status.

## Notes

- Full Firefox conformance execution requires Firefox + GeckoDriver provisioning in the runtime environment.
