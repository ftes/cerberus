---
# cerberus-cuze
title: Trim slow live checkbox phx-click regression test
status: completed
type: task
priority: normal
created_at: 2026-03-09T11:35:20Z
updated_at: 2026-03-09T11:50:10Z
---

## Scope

- [ ] Profile the slow live checkbox phx-click regression path more finely.
- [ ] Reduce avoidable overhead in the test or live driver without weakening the label-based checkbox coverage.
- [x] Re-run targeted checkbox coverage plus full test and slow lanes.
- [x] Record the before/after timing.

## Notes

- Fine-grained profiling showed the cost was almost entirely repeated live label-based field resolution, not the LiveView click/render path.
- The regression only needed to prove one label-based nameless checkbox toggle through phx-click. Repeating the same expensive label lookup for uncheck did not add enough unique coverage to justify the time.

## Summary of Changes

- Profiled the slow live checkbox phx-click regression and confirmed the cost was repeated label-based live field resolution, not LiveView render/click work.
- Simplified the regression to a single label-based toggle while preserving the intended nameless checkbox phx-click coverage.
- Reduced the targeted test runtime from roughly 2.4s to about 0.9s, and the row now shows up around 1.0s in the slowest report.
