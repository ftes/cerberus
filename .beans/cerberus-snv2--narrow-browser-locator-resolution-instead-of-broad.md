---
# cerberus-snv2
title: Narrow browser locator resolution instead of broad candidate scans
status: scrapped
type: task
priority: normal
created_at: 2026-03-08T19:34:57Z
updated_at: 2026-03-08T20:09:58Z
---

## Scope

- [ ] Replace broad candidate-first browser locator resolution with narrower selector-driven resolution where possible.
- [ ] Preserve current Cerberus locator semantics.
- [ ] Re-measure EV2 browser comparison rows after the refactor.

## Notes

- Deferred from the current EV2 performance investigation.
- Current evidence suggests this is worth pursuing later, but it is not yet proven to be the dominant remaining gap.
- Keep this separate from transport/protocol timing work so the next optimization is based on measured evidence.

## 2026-03-08 implementation notes

- Added a narrow first-match fast path for browser action resolution in action_helpers.
- The fast path walks only selector-prefiltered DOM elements, builds candidates lazily, and short-circuits on the first match when no count or position filters are involved.
- Existing broad candidate collection remains the fallback for failure diagnostics and count/position semantics.
- Focused browser suites stayed green after the change.
- EV2 re-measurement on project_form_feature_cerberus_test.exs did not show a meaningful improvement:
  - before this change the stable row was roughly 17.9s
  - after this change the clean sequential rerun was 18.3s
- Profiled EV2 row also remained dominated by script.evaluate roundtrip latency, not browser helper JS. This confirms narrow-first action resolution is directionally cleaner but not a material speed win on the current bottleneck.

## Reasons for Scrapping

- The narrow-first action path made browser action resolution inconsistent with the broader fallback path.
- It did not produce a meaningful performance improvement on the stable EV2 comparison row.
- Current evidence says the dominant bottleneck is BiDi script.evaluate roundtrip latency, so this complexity is not justified right now.
