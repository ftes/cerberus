---
# cerberus-t6i8
title: Add helper locator cross-driver conformance matrix and live selector-edge tests
status: completed
type: task
priority: normal
created_at: 2026-02-27T17:38:59Z
updated_at: 2026-02-27T17:39:48Z
parent: cerberus-zqpu
---

Implement dedicated conformance harness coverage for new helper locators (`text/link/button/label/role/testid`) with emphasis on LiveView `render_click` selector conversion behavior.

## Scope
- Add static/browser conformance scenarios using helper locators across navigation + forms.
- Add live/browser conformance scenarios stressing duplicate live button labels where selector conversion must disambiguate `render_click` target.
- Add explicit cross-driver unsupported conformance checks for `testid` helper in this slice.

## Acceptance
- [x] static vs browser conformance harness covers helper `link/button/label/role/text` flows.
- [x] live vs browser conformance harness covers duplicate-label live button click behavior.
- [x] conformance test verifies explicit unsupported `testid` behavior across drivers.
- [x] fixture/docs updated for selector-edge route used by the suite.

## Summary of Changes
- Added `Cerberus.Fixtures.SelectorEdgeLive` and routed it at `/live/selector-edge` for duplicate-button-label selector-edge behavior.
- Added `test/core/helper_locator_conformance_test.exs` with cross-driver harness scenarios for helper locators:
  - static vs browser forms/navigation (`label`, `button`, `role(:textbox|:button|:link)`, `link`, `text`)
  - live vs browser duplicate button-label clicks (`button`, `role(:button)`) on live route
  - live vs browser role-link navigation from live route
  - static vs browser explicit unsupported behavior for `testid`
- Updated fixture docs (`docs/fixtures.md`) to include the new selector-edge live route.
- Verified suite with `mix test test/core/helper_locator_conformance_test.exs`.
