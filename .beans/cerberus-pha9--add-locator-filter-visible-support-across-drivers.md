---
# cerberus-pha9
title: Add locator filter visible support across drivers
status: todo
type: feature
priority: normal
created_at: 2026-03-06T09:40:25Z
updated_at: 2026-03-06T09:40:34Z
blocked_by:
    - cerberus-7b3a
---

## Goal
Add first-class locator visibility filtering through `filter` so locator resolution can constrain candidates by visibility state (Playwright-style), independent of assertion-only visibility options.

## Problem
Visibility in Cerberus is currently split:
- Assertions support `visible: true | false | :any`.
- Locator state filters support `checked/disabled/selected/readonly`, but not `visible`.
- Browser actionability enforces visibility for actions, but locator filtering cannot express visibility intent directly.

This leaves a gap for authoring explicit locator-level visibility constraints and causes ambiguity between candidate selection and assertion semantics.

## Current Behavior and Technical Context
Assertion visibility exists
- Assert option schema has `visible` as `true | false | :any`:
  - `lib/cerberus/options.ex` lines 327-332
- Static and live assertions consume `visible` and pass through to HTML extraction:
  - `lib/cerberus/driver/static.ex` lines 332-334, 367-369, 398-400
  - `lib/cerberus/driver/live.ex` lines 566-568, 601-603, 633-635
- HTML assertion visibility split logic:
  - `lib/cerberus/html/html.ex` lines 1377-1379

Locator state filters exclude visibility today
- Query state filter keys are currently only:
  - `[:checked, :disabled, :selected, :readonly]` in `lib/cerberus/query.ex` line 6
- `matches_state_filters?/2` consumes only those keys:
  - `lib/cerberus/query.ex` lines 192-203
- HTML locator candidate filters rely on `Query.matches_state_filters?/2`:
  - examples in `lib/cerberus/html/html.ex` lines 357, 384, 457, 1185, 1266
- Browser in-page resolver similarly applies only the same state keys:
  - `matchesStateFilters` in `lib/cerberus/driver/browser/action_helpers.ex` lines 506-515
  - candidate filter usage at line 1240

Browser visibility/actionability exists but is separate
- Browser actionability visibility gate is in `isElementVisible` + `prepareTargetForAction`:
  - `lib/cerberus/driver/browser/action_helpers.ex` lines 342-384
- This is pre-action readiness, not locator-level filtering semantics.

Existing visibility tests are assertion-focused
- `test/cerberus/live_visibility_assertions_test.exs` lines 19-25
- `test/cerberus/locator_parity_test.exs` lines 356-363
- `test/cerberus/api_examples_test.exs` line 48

Related in-progress work
- `cerberus-7b3a` is already in-progress for `filter` API introduction and scope/piping semantics.
- This bean is specifically for adding visibility semantics to locator filters once `filter` exists.

## Product Direction
Add locator-level visibility filtering as part of `filter` semantics.

Recommended behavior
- Support `visible: true | false` in locator filter options.
- Optional support for `visible: :any` can be considered for consistency with assertion options.
- Locator visibility filtering should affect candidate selection for actions and locator assertions.

Important distinction
- Keep assertion `visible` option for text/assertion semantics.
- Do not collapse assertion visibility into locator visibility by default.
- If both are provided, define deterministic behavior (or explicit validation error).

Playwright alignment intent
- Align with Playwright locator-level visibility filtering model (`locator.filter({ visible: ... })`) while preserving Cerberus assertion ergonomics.

## Open Questions
- Should locator filter `visible` support only booleans, or include `:any` for API symmetry?
- If a call includes both locator `filter(visible: ...)` and assert option `visible: ...`, should we:
  - allow and compose,
  - or reject conflicting combinations?
- Should hidden determination in non-browser stay current style/attr heuristic, or be tightened?
- Should visible filtering be available in all locator contexts (`has`, `has_not`, nested filters) from day one?

## Proposed Implementation Plan
1. Extend filter/state model
- Add `visible` support to shared locator filter option handling.
- Update `Query.matches_state_filters?/2` (or sibling path) to include visibility checks.

2. Implement non-browser visibility state resolution for candidates
- Reuse existing hidden detection paths in HTML modules where possible.
- Ensure visibility state is available in maps passed to state filtering.

3. Implement browser locator visibility filtering
- Extend browser action helper state filtering to handle `visible` key.
- Reuse/align with existing `isElementVisible` semantics where appropriate.

4. Wire through locator/filter API
- Integrate with `filter` API from `cerberus-7b3a`.
- Ensure nested locator filters (`has`, `has_not`) can carry visibility constraints.

5. Define assert interaction contract
- Document and enforce behavior when both locator visibility filter and assertion `visible` option are present.

6. Add cross-driver tests
- Candidate-selection parity tests using identical visible/hidden siblings.
- Action target-selection tests with locator `visible` filter.
- Assertion tests for combined locator-visible + assert-visible usage.

## Acceptance Criteria
- Locator filter supports visibility constraints across browser/live/static candidate resolution.
- Behavior is deterministic and documented when combined with assertion `visible` option.
- Existing assertion visibility behavior remains intact unless intentionally changed.
- New tests cover positive and negative visibility-filter cases across driver matrices.

## Implementation Checklist
- [ ] Add `visible` to locator/filter option model and validation
- [ ] Extend query/state filter logic to evaluate visibility
- [ ] Add candidate visibility state in static/live HTML mapping paths
- [ ] Extend browser in-page state filter logic for visibility
- [ ] Integrate with `filter` API and nested filter composition
- [ ] Define and implement assert-visible + locator-visible interaction rules
- [ ] Add cross-driver tests for locator visibility filtering
- [ ] Run `mix format`
- [ ] Run targeted `mix test` with random `PORT=4xxx`
- [ ] Run `mix do format + precommit + test + test --only slow`

## Validation Notes
- Source environment before tests: `source .envrc`.
- Keep browser lane Chrome-only per current local policy.

## Dependencies and Coordination
- Depends on completion or merge path from `cerberus-7b3a` (filter API introduction).
- Coordinate with `cerberus-84zg` and `cerberus-phtj` so visibility filter semantics and force/actionability semantics remain coherent.
