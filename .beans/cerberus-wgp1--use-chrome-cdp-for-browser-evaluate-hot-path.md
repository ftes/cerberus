---
# cerberus-wgp1
title: Use Chrome CDP for browser evaluate hot path
status: completed
type: task
priority: normal
created_at: 2026-03-08T20:34:26Z
updated_at: 2026-03-08T20:44:26Z
---

## Scope

- [ ] Add a Chrome-only CDP page evaluator for browser script evaluation.
- [ ] Route browser evaluate hot paths through CDP when available, with BiDi fallback.
- [x] Verify focused Cerberus browser suites and re-measure the stable EV2 browser comparison row.

## Notes

- Keep lifecycle, navigation, tabs, and prompts on BiDi.
- Limit the change to evaluate-based read and action helper execution.
- Use the raw Chrome BiDi vs CDP benchmark as the justification for this slice.

## Summary of Changes

- Added a Chrome-only CDP page evaluator that attaches to the existing browsing context by debuggerAddress and page target id.
- Routed browser evaluate-based operations through CDP on Chrome, with BiDi retained for lifecycle, navigation, readiness, prompts, and fallback.
- Verified Cerberus browser suites and re-measured the stable EV2 row. The project_form_feature_cerberus_test.exs row dropped from the prior 18.9s baseline to 9.0s on the first rerun and 9.9s on the immediate rerun, versus 6.0s for the matching Playwright file.
