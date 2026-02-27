---
# cerberus-g0jq
title: 'Browser driver slice 1: minimal BiDi one-shot text assertions'
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:28Z
updated_at: 2026-02-27T16:00:48Z
parent: cerberus-sfku
blocked_by:
    - cerberus-k4m0
---

## Scope
Implement minimal Browser driver over WebDriver BiDi for one-shot `visit/click/assert_has/refute_has`.

## Details
- use BiDi session transport (no CDP/classic webdriver APIs).
- start with Chromium path; Firefox compatibility tracked separately.
- evaluate text assertions in-page and return structured observed data.

## Technical Steps
- [x] establish BiDi session + navigation.
- [x] implement click by text locator for deterministic fixtures.
- [x] implement one-shot text lookup + matching.
- [x] capture page URL/title/raw matches for diagnostics.

## Done When
- [x] browser driver can execute slice 1 conformance scenarios.
- [x] failures include page-side observed values.

## Summary of Changes
- Confirmed the browser driver already implements BiDi-backed `visit`, text-based `click`, and one-shot `assert_has/refute_has` flows with structured observed diagnostics (`path`, `title`, `texts`, `matched`).
- Verified slice behavior end-to-end by running `mix test test/core/cross_driver_text_test.exs test/core/api_examples_test.exs` with the pinned local browser runtime.
- Confirmed browser conformance scenarios pass and failure formatting includes page-side observed details through existing assertion plumbing.
