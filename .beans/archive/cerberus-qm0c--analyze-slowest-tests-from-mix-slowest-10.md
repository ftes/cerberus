---
# cerberus-qm0c
title: Analyze slowest tests from mix --slowest 10
status: completed
type: task
priority: normal
created_at: 2026-03-03T17:17:40Z
updated_at: 2026-03-03T17:20:44Z
---

## Goal
Run mix test --slowest 10, identify top time contributors, and propose practical improvements.

## Todo
- [x] Run slowest test profile
- [x] Analyze bottlenecks from output
- [x] Recommend actionable improvements

## Summary of Changes
- Ran source .envrc and mix test --slowest 10 with a random open PORT to avoid listener conflicts.
- Captured top 10 slowest tests from a full suite run: 17.6s combined, 18.2 percent of total runtime.
- Identified dominant hotspots:
  - HelperLocatorBehaviorTest browser negative-action cases at lines 132, 147, 189, 198.
  - BrowserMultiSessionBehaviorTest browser isolation and tab workflow cases.
  - CrossDriverMultiTabUserTest browser case.
  - LiveNestedScopeBehaviorTest browser scoped not-found case.
  - BrowserExtensionsTest with_popup capture flow.
- Root-cause pattern: browser negative-action expectations and strict-uniqueness failures pay full browser ready timeout costs (default 1500ms), while multi-session popup flows pay real browser startup and tab-context overhead.
- Recommended improvements:
  - Add an explicit action timeout option for browser actions, then set low timeout in tests that intentionally assert failure paths.
  - Apply per-session reduced browser ready timeout in targeted negative tests where correctness does not depend on long waits.
  - Reuse shared browser sessions in modules that currently start fresh browser sessions per test when isolation is not required.
  - Mark multi-session and popup workflow tests as slow if default local feedback loop time should be reduced.
