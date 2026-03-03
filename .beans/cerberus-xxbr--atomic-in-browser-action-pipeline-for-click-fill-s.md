---
# cerberus-xxbr
title: Atomic in-browser action pipeline for click fill submit
status: in-progress
type: task
priority: normal
created_at: 2026-03-03T11:30:52Z
updated_at: 2026-03-03T11:53:12Z
parent: cerberus-dsr0
---

Implement one-evaluate in-browser action pipeline for click, submit, and fill_in with strict target and actionability checks.\n\nScope:\n- [x] Merge resolve and execute into one browser helper entrypoint for these ops.\n- [ ] Remove extra pre and post readiness waits from success paths.\n- [x] Remove success snapshot requirement from hot path.\n- [x] Keep deterministic error reasons and target diagnostics.\n- [x] Verify chrome coverage for these ops; firefox verification deferred for now.

\nProgress notes:\n- Kept post-action readiness sync for click and submit to preserve current_path behavior in browser tests.\n- Removed pre-action readiness on click, fill_in, and submit hot paths.\n- Firefox fallback tuning was intentionally dropped to keep implementation clean; feature verification is currently chrome-focused by decision.
