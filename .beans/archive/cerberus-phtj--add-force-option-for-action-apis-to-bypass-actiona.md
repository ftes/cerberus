---
# cerberus-phtj
title: Add force option for action APIs to bypass actionability checks
status: completed
type: feature
priority: normal
created_at: 2026-03-06T09:39:50Z
updated_at: 2026-03-06T12:33:13Z
---

## Goal
Introduce a Playwright-style `force` option for action APIs so callers can explicitly bypass actionability checks when needed.

## Problem
Actionability checks currently run by default in browser actions (target attached, scroll, visibility) with no explicit API escape hatch. This can block legitimate advanced flows where users intentionally act on otherwise non-actionable targets.

## Current Behavior and Technical Context
Browser actionability path
- Browser action helper performs actionability precheck before executing actions:
  - `helper.prepareTargetForAction` in `lib/cerberus/driver/browser/action_helpers.ex` lines 373-384
  - invocation in `helper.performResolved` at lines 1415-1418
- Visibility check inside actionability gate:
  - `isElementVisible` in `lib/cerberus/driver/browser/action_helpers.ex` lines 342-369
  - `target_not_visible` reject at lines 380-381

No force option in public action schemas
- Action option schemas currently include state/count/position filters but no `force`:
  - click: `lib/cerberus/options.ex` lines 311-325
  - fill_in: `lib/cerberus/options.ex` lines 349-363
  - submit: `lib/cerberus/options.ex` lines 365-379
  - upload: `lib/cerberus/options.ex` lines 381-395
  - select: `lib/cerberus/options.ex` lines 397-418

No force field in browser action payload
- Browser payload currently sends selector/locator/state/count/position fields; no `force` field:
  - `lib/cerberus/driver/browser.ex` lines 708-741

Existing visibility actionability regression coverage
- Browser hidden target click is asserted to fail:
  - `test/cerberus/browser_extensions_test.exs` lines 86-98
- Browser offscreen auto-scroll behavior is asserted:
  - `test/cerberus/browser_extensions_test.exs` lines 100-114

Related open/nearby work
- Disabled parity follow-up bean exists: `cerberus-84zg`
- Locator filter API in-progress bean exists: `cerberus-7b3a` (adjacent but separate)

## Product Direction
Add `force: true` as an explicit override for actionability checks.

Default behavior
- Keep strict default (`force: false`).
- Current actionability behavior remains unchanged unless caller opts in.

Force behavior
- `force: true` bypasses actionability checks that gate interaction readiness.
- Structural and operation-type validation still applies:
  - examples: field kind mismatch, missing option, no matched candidate, bad payload.
- Disabled constraints that are part of explicit semantic checks should be defined per operation (see open questions below).

Driver strategy
- Browser: implement full behavior (real bypass of actionability gate).
- Live/static: accept `force` option for API parity first; if there are driver-side readiness gates, bypass those where feasible.
- Do not fabricate non-browser browser-like actionability just to support force.

## Open Questions
- Should `force` bypass disabled checks too, or only visibility/attachment/readiness checks?
- Should `force` apply uniformly to all actions (`click`, `submit`, `fill_in`, `select`, `choose`, `check`, `uncheck`, `upload`) or only click-like actions?
- Should `force` be available in scoped helpers with no additional options translation changes?
- Error messaging: when `force` is used and action still fails, should failure include explicit note that force was enabled?

## Proposed Implementation Plan
1. Extend options and validation
- Add `force: boolean()` to relevant action schemas in `lib/cerberus/options.ex`.
- Validate and pass through in all action entry points.

2. Plumb `force` into browser action payload
- Add payload key in `build_action_payload/6` in `lib/cerberus/driver/browser.ex`.
- Ensure expression payload decoding treats missing as false.

3. Apply force semantics in JS helper
- Update `performResolved` path in `lib/cerberus/driver/browser/action_helpers.ex`.
- Skip `prepareTargetForAction` when `force` is true.
- Keep operation-type guards and other semantic checks.

4. Align driver behavior and docs
- Accept `force` in live/static action APIs.
- Implement parity/no-op semantics intentionally and document clearly.

5. Add tests
- Browser tests proving hidden/offscreen interactions can succeed with `force: true` where semantically valid.
- Tests confirming default strict behavior remains unchanged.
- Tests verifying unsupported/mismatch failures still fail with `force: true`.
- Cross-driver API acceptance tests for `force` option shape.

## Acceptance Criteria
- `force` is accepted by action APIs and validated as boolean.
- Browser action path bypasses actionability gate when `force: true`.
- Default action behavior remains strict and current tests continue to pass.
- New tests cover forced and non-forced behavior for click and at least one form action.
- Docs/examples mention `force` and explain intended scope.

## Implementation Checklist
- [x] Add `force` to action option schemas and validations
- [x] Add `force` to browser action payload plumbing
- [x] Implement force bypass in browser action helper gate
- [x] Define and implement force semantics for disabled checks
- [x] Add browser tests for hidden target with `force: true`
- [x] Add browser tests preserving strict default behavior
- [x] Add cross-driver API acceptance tests for `force`
- [x] Update docs/examples for `force`
- [x] Run `mix format`
- [x] Run targeted `mix test` with random `PORT=4xxx`
- [x] Run `mix do format + precommit + test + test --only slow`

## Validation Notes
- Source environment before test runs: `source .envrc`.
- Use random test port per AGENTS guidance.

## Dependencies and Coordination
- Related to `cerberus-84zg` (actionability parity), but this bean focuses specifically on introducing an explicit override.
- Can proceed independently from `cerberus-7b3a` filter work.

## Summary of Changes
- Added `force: boolean` action option support to click/fill_in/check/choose/select/submit/upload schemas and types.
- Plumbed `force` into browser action payloads and implemented `force: true` behavior by skipping browser actionability prechecks (`prepareTargetForAction`).
- Defined force semantics to bypass readiness/actionability checks only; operation-level disabled/type checks still apply.
- Added browser coverage for forced hidden clicks and cross-driver acceptance coverage for `force` options.
- Updated docs/examples (`docs/getting-started.md`, `docs/cheatsheet.md`) to include `force`.
- Validated with targeted suites and full checks (`MIX_ENV=test mix do format + precommit + test + test --only slow`).
