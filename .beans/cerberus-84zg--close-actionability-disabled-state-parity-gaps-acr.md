---
# cerberus-84zg
title: Close actionability disabled-state parity gaps across drivers
status: todo
type: bug
created_at: 2026-03-06T09:32:14Z
updated_at: 2026-03-06T09:32:14Z
---

## Problem
Cerberus does not enforce disabled-state actionability consistently across browser, live, and static drivers. This creates cross-driver drift and diverges from Playwright-style expectations for actions that should fail on disabled controls.

## Why This Matters
- Users expect the same API call to fail or pass consistently across drivers.
- Browser behavior is currently stricter for some operations and looser for others.
- Live and static behavior differ from each other in click handling.
- Current behavior can hide bugs in one lane and surface them in another.

## Detailed Audit Context
Audit source: cerberus-lhp6 completed on 2026-03-06.

Browser driver actionability gate
- Browser actionability precheck verifies target attached, scrolls into view, and checks visibility:
  - lib/cerberus/driver/browser/action_helpers.ex lines 373-384
- Actionability gate is invoked for every resolved action:
  - lib/cerberus/driver/browser/action_helpers.ex lines 1415-1418
- Visibility rejection reason is target_not_visible.

Browser driver disabled checks
- Explicit disabled rejection exists for:
  - select: lib/cerberus/driver/browser/action_helpers.ex line 1435
  - choose: lib/cerberus/driver/browser/action_helpers.ex line 1533
  - check and uncheck: lib/cerberus/driver/browser/action_helpers.ex line 1545
  - upload: lib/cerberus/driver/browser/action_helpers.ex line 1554
- Explicit disabled precheck is not present in click and submit action execution path before element.click:
  - lib/cerberus/driver/browser/action_helpers.ex lines 1598-1625
- Browser error mapping currently translates field_disabled to operation-specific messages:
  - lib/cerberus/driver/browser.ex lines 672-707

Static driver behavior
- Static click path resolves link or button and executes without a dedicated disabled actionability guard:
  - lib/cerberus/driver/static.ex lines 155-175
- Static select delegates to Html.select_values, which rejects disabled select fields and disabled options:
  - lib/cerberus/html/html.ex lines 401-419
  - lib/cerberus/html/html.ex lines 659-677
- Static choose, check, uncheck, fill_in, and upload rely on field matching plus type checks, but do not perform a default disabled actionability rejection.

Live driver behavior
- Live click has a button disabled guard that returns no button matched locator:
  - lib/cerberus/driver/live.ex lines 1640-1652
- Live select also delegates to Html.select_values and inherits disabled select and option rejection.
- Live fill_in, choose, check, uncheck, and upload do not uniformly enforce disabled rejection as a default actionability rule.

Locator and filter layer context
- Disabled can be used as an opt-in locator state filter in Query matching:
  - lib/cerberus/query.ex lines 192-213
- Browser action resolver also applies state filters when disabled is provided in options:
  - lib/cerberus/driver/browser/action_helpers.ex lines 506-515
  - lib/cerberus/driver/browser/action_helpers.ex line 1240
- This means some disabled behavior today is opt-in filter behavior, not default actionability behavior.

Existing tests relevant to this gap
- Browser hidden-target actionability visibility coverage:
  - test/cerberus/browser_extensions_test.exs lines 86-98
- Disabled select coverage in live and browser matrix:
  - test/cerberus/helper_locator_behavior_test.exs lines 286-299
- Disabled option coverage in static and browser matrix:
  - test/cerberus/select_choose_behavior_test.exs lines 88-95
- No dedicated coverage currently proves disabled click and disabled submit parity across all drivers.

## Scope
In scope
- Define and enforce a consistent disabled-state actionability contract for click, submit, fill_in, choose, check, uncheck, select, and upload across browser, live, and static where feasible.
- Make failure reasons consistent enough for cross-driver expectations and debugging.
- Add conformance tests covering disabled-state action behavior per operation across driver matrices.

Out of scope
- Playwright-style hit-target interception checks.
- Stability checks and animation settling semantics.
- New visibility actionability checks in non-browser drivers.

## Proposed Contract Direction
- Default behavior should reject actions on disabled targets consistently across drivers.
- Disabled option and disabled select-field rejection stays explicit for select.
- Optional disabled filter remains supported and should compose with default actionability.
- Error messages should remain operation-specific where useful, but driver-independent in meaning.

## Open Design Questions
- Should disabled click on button return no button matched locator or a direct matched element is disabled style reason?
- Should disabled submit map to matched submit control is disabled versus reusing matched field is disabled?
- For links and generic phx-click elements, disabled semantics are not native HTML in the same way as form controls; confirm desired behavior.

## Acceptance Criteria
- For each operation, disabled target behavior is documented and consistent across browser, live, static unless impossible by design.
- New tests fail on current main and pass after implementation.
- Existing parity tests remain green.
- No regressions in action target resolution and locator filter behavior.

## Implementation Checklist
- [ ] Define final disabled actionability contract by operation and driver
- [ ] Implement browser disabled checks for click and submit where missing
- [ ] Implement live disabled checks for fill_in, choose, check, uncheck, upload where missing
- [ ] Implement static disabled checks for click, fill_in, choose, check, uncheck, upload where missing
- [ ] Align failure reason mapping and public assertion error text
- [ ] Add cross-driver conformance coverage for disabled click and disabled submit
- [ ] Add cross-driver conformance coverage for disabled fill_in, choose, check, uncheck, and upload
- [ ] Validate existing select disabled and disabled option tests still pass
- [ ] Run mix format
- [ ] Run targeted mix tests with random PORT 4xxx after each logical change
- [ ] Run mix do format + precommit + test + test --only slow before merge

## Validation Plan
- Add focused tests that assert disabled-state failures for each action in static, live, and browser matrices.
- Prefer fixture controls that expose both enabled and disabled variants with identical labels to avoid ambiguous matching.
- Verify behavior with and without disabled filter option to ensure filter semantics do not mask default actionability.

## Notes for Assignee
- This bean is a follow-up implementation bean from cerberus-lhp6 audit.
- Prior related deferred bean: cerberus-0o0q, which is about hit-target and stability checks, not disabled-state actionability.
