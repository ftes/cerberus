---
# cerberus-99o6
title: Drive cerberus-new against Cerberus real parity suite
status: completed
type: feature
priority: normal
created_at: 2026-03-07T18:34:53Z
updated_at: 2026-03-07T18:42:05Z
---

Run cerberus-new against the real Cerberus test surface and keep iterating on missing behaviors until the new implementation is usable beyond the fixture harness.

- [x] Read the existing real parity and behavior tests to choose a low-conflict integration slice
- [x] Build a minimal bridge or copied slice that runs original Cerberus scenarios against cerberus-new
- [x] Fix the first failing behavior gaps in cerberus-new
- [x] Verify with targeted tests in cerberus-new and commit the progress

## Summary of Changes

- Added a real-fixture bridge suite in cerberus-new that mirrors key owner-form, static form-shape, and LiveView form synchronization scenarios from the original Cerberus test surface.
- Expanded the cerberus-new fixture app with owner-form redirects, profile version pages, and merged request param handling.
- Fixed Phoenix static redirect following with an outer request loop that preserves seeded request headers across redirects.
- Fixed static form state resets across page transitions and corrected browser static GET submit semantics to prefer explicit submitter overrides only when present.
