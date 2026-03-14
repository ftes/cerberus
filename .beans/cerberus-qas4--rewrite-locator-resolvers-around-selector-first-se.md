---
# cerberus-qas4
title: Rewrite locator resolvers around selector-first semantics
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T08:26:35Z
updated_at: 2026-03-14T15:34:17Z
---

Rewrite browser and LazyHTML locator resolution from scratch around a selector-first, narrow-resolution model guided by Playwright. Start by removing the temporary live label fast path, then rebuild static and live resolution, broaden browser coverage carefully, and enable parity tests incrementally while keeping complexity minimal.


## Notes

- rewrote shared LazyHTML form-field resolution around selector-first explicit-label, implicit-label, and attr-specific queries instead of the older generic candidate matcher
- rewrote shared link and button resolution to query narrowed selectors first and build matches directly, keeping the recursive generic matcher only where locator composition still needs it
- rewrote shared submit-button resolution to query submit-capable controls directly and derive owner-form metadata from the matched node instead of scanning forms and owner-form branches separately
- preserved EV2 live notifications row improved from roughly 14s before this rewrite series to 9.8s on the latest warm Cerberus rerun, versus 2.4s for the restored PhoenixTest baseline
- browser resolver rewrite is still pending; this slice only covered shared LazyHTML resolution used by static and live

## Notes
- kept role locator semantics broad for now (matching accessible-name source variants) after a stricter single-name rewrite broke existing static/live parity coverage
- selector-first shared button resolution stays in place; the major win in this slice came from avoiding unconditional state projection during matching

## Notes
- browser locator assertions now mirror the shared count-first, diagnostics-on-failure algorithm used by static/live
- preserved EV2 browser row project_form_feature_cerberus_test stayed about 16.7s after this slice, so browser resolver JS is no longer the dominant gap there
- profile on the preserved browser row shows the remaining hotspot is still script.evaluate transport roundtrip and evaluate_direct/evaluate_action_direct volume, not locator matching time

## Notes
- added a cheap one-round matcher contract harness that now covers 43 shared HTML/Node DOM cases across assertion and action resolution, including benchmark-style has/has_not filters, closest(from:), count/refute count constraints, or_/not_ composition, submit nested filters, and action ambiguity failures
- expanded the focused contract test to lock those normalized results in place and kept the cross-lane runner green
- normalized range-based between count filters in Cerberus.Query so the low-level round resolvers accept the same tuple and range shapes as the higher-level APIs

## Notes
- expanded the one-round matcher contract to cover count-position action selection for click/fill_in/submit, wrapped-label and aria-labelledby field matching, multiple-label field association, and the submit nested or_ inside has ambiguity case
- added immediate actionability/state matching coverage for disabled and readonly action filters in the shared HTML/Node DOM harness
- the new repeated-card action locator case currently documents a real gap: button action locators with nested has/has_not filters still resolve to no match in both lanes

## Notes
- fixed the button-role matcher confusion in the new contract cases by aligning role-name exactness with real accessible-name semantics; click action locators with role + has/has_not now resolve correctly when the role name is intentionally non-exact
- expanded the shared contract to cover wrapped labels, aria-labelledby, multi-label fields, count-position action selection across click/fill_in/submit, and the repeated-card one-shot action locator
- migration status: the new round resolver/payload structure is in place for the cheap harness and shared HTML APIs, but the browser and driver runtimes still layer their polling/action execution logic on top of those matchers rather than fully dispatching through the round APIs
