---
# cerberus-84zg
title: Close actionability disabled-state parity gaps across drivers
status: in-progress
type: bug
priority: normal
created_at: 2026-03-06T09:32:14Z
updated_at: 2026-03-06T21:14:12Z
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
- [x] Define final disabled actionability contract by operation and driver
- [x] Implement browser disabled checks for click and submit where missing
- [x] Implement live disabled checks for fill_in, choose, check, uncheck, upload where missing
- [x] Implement static disabled checks for click, fill_in, choose, check, uncheck, upload where missing
- [x] Align failure reason mapping and public assertion error text
- [x] Add cross-driver conformance coverage for disabled click and disabled submit
- [x] Add cross-driver conformance coverage for disabled fill_in, choose, check, uncheck, and upload
- [x] Validate existing select disabled and disabled option tests still pass
- [x] Run mix format
- [x] Run targeted mix tests with random PORT 4xxx after each logical change
- [ ] Run mix do format + precommit + test + test --only slow before merge

## Validation Plan
- Add focused tests that assert disabled-state failures for each action in static, live, and browser matrices.
- Prefer fixture controls that expose both enabled and disabled variants with identical labels to avoid ambiguous matching.
- Verify behavior with and without disabled filter option to ensure filter semantics do not mask default actionability.

## Notes for Assignee
- This bean is a follow-up implementation bean from cerberus-lhp6 audit.
- Prior related deferred bean: cerberus-0o0q, which is about hit-target and stability checks, not disabled-state actionability.

## EV2 Migration Context (2026-03-06)

Source migration work:
- cerberus-pg35 (`Migrate another EV2 PhoenixTest slice to Cerberus`)
- downstream app under test: `/Users/ftes/src/ev2-copy`
- migrated files in that slice:
  - `test/features/generate_timecards_test.exs` (non-browser, ConnCase + Cerberus)
  - `test/features/create_offer_test.exs` (browser, ConnCase + Cerberus)

Why this bean matters now
- The browser migration exposed that Cerberus actions are not yet waiting for dependent control actionability the way Playwright does.
- The concrete EV2 pattern is a LiveView form where selecting one field enables or repopulates another field asynchronously.
- With Playwright/PhoenixTestPlaywright this generally worked without extra test-side waits because browser actions waited for actionability before acting.
- With Cerberus today, the same migrated tests often need explicit intermediate assertions like “job title select is no longer disabled” before calling `select/3` or `check/3`.
- Those intermediate assertions are diagnostic and can unblock a migration, but they are not the right long-term API shape.

Concrete failing scenarios seen during migration
- In `Features.CreateOfferTest`, after selecting `Department`, the next dependent control may still be disabled for a short period:
  - `Job title` select remains disabled before selecting `Rushes Runner` or `Department Driver`
  - `Search job titles from all departments?` checkbox remains disabled before checking it
- Example failure shapes observed from Cerberus browser actions:
  - `select failed: matched select field is disabled`
  - `check failed: matched field is disabled`
- These failures occurred even after successful navigation to `/projects/:id/offers/new`; the gap is not just page visit readiness, it is post-change control readiness.

Driver-specific expectation that emerged from review
- `:browser`
  - actions should wait for actionability before acting, broadly aligned with Playwright semantics
  - for form controls, this includes waiting until the control is enabled
  - ideally also continues to cover browser-native concerns like visibility/attached/stability/event-receivability where applicable
- `:live`
  - should not try to emulate full browser actionability
  - but should reasonably wait for driver-observable readiness on form controls, especially “exists and is no longer disabled” before attempting actions like `fill_in`, `select`, `check`, `choose`, `uncheck`, `upload`, maybe `click` on buttons
- `:static`
  - should not auto-wait; snapshot HTML does not change on its own

Why this is not just a test helper issue
- We temporarily removed or reduced custom EV2 helper waits like `await_offer_form_connect/1` because they were over-specific and still did not solve dependent-control readiness.
- The real issue showed up after navigation succeeded and the form was present, but before the dependent control had become actionable.
- That is exactly the boundary Playwright’s action auto-wait usually handles.
- Requiring every browser migration to manually assert enabled state before each dependent action will make Cerberus browser tests noisy and less idiomatic.

Concrete examples worth turning into Cerberus regression coverage
- Browser:
  - select a parent field in a LiveView form, then immediately `select` a dependent disabled-to-enabled select; Cerberus should wait and succeed once enabled
  - select a parent field in a LiveView form, then immediately `check` a dependent disabled-to-enabled checkbox; Cerberus should wait and succeed once enabled
- Live:
  - for live driver action execution, retry until the target control is no longer disabled for form control actions where the HTML can change in response to prior LiveView events
- Negative coverage:
  - if a control stays disabled past timeout, action should still fail with the current operation-specific disabled message

Related Cerberus work encountered during this migration
- `Browser.user_agent_for_sandbox/2` needed to tolerate the `:already_shared` sandbox-owner case from non-async `ConnCase` setup, not just `:already_owner` / `:allowed`
- A separate `Options` regression in `validate_position_opts!/3` broke locator assertions during this work; that was incidental, not the core actionability gap
- Existing Cerberus SQL sandbox coverage also shows async task ownership gaps in fixture LiveViews with `assign_async`, but that is distinct from this bean’s main focus

Suggested implementation direction
- Browser driver
  - move the disabled-state wait into browser action functions themselves rather than expecting tests to assert enabled state first
  - start with `select`, `check`, `uncheck`, `choose`, `fill_in`, and submit/button-like click paths on form controls
  - use the same timeout budget as the action
- Live driver
  - for form-control actions, add a smaller “wait until enabled” retry loop based on rendered HTML / live view state before attempting the action
  - do not attempt full Playwright actionability semantics like hit-target or stability
- Static driver
  - keep immediate behavior; disabled checks can still reject, but no waiting loop

Desired end-state for downstream migrations
- Migrated browser tests in EV2 should be able to say:
  - `select(~l"Department"l, option: ~l"Production"e)`
  - `select(~l"Job title"l, option: ~l"Rushes Runner"e)`
- without inserting an extra explicit “wait until Job title is enabled” assertion in between
- same general principle for dependent checkbox/radio/input actions on live-updating forms

## Docs Follow-up\n\nIf this bean lands as intended, simplify MIGRATE_FROM_PHOENIX_TEST.md by removing or narrowing the temporary guidance about explicit enabled-state waits for dependent LiveView controls. Keep only any migration notes that still apply to target-side readiness not covered by automatic action waiting.
