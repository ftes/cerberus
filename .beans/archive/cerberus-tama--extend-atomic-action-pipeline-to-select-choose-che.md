---
# cerberus-tama
title: Extend atomic action pipeline to select choose check uncheck upload
status: completed
type: task
priority: normal
created_at: 2026-03-03T11:32:12Z
updated_at: 2026-03-03T12:16:50Z
parent: cerberus-dsr0
---

Apply lightweight one-evaluate action flow to remaining form action ops beyond click submit fill_in.\n\nScope:\n- [x] Move select choose check uncheck upload to atomic in-browser resolve plus execute flow.\n- [x] Remove pre and post readiness waits from success hot paths for these ops.\n- [x] Remove post-action success snapshot usage on these op paths.\n- [x] Preserve strict uniqueness and actionability failures with clear diagnostics.\n- [x] Verify roundtrip and stability improvements on chrome; firefox verification deferred by decision.

\n## Summary of Changes\n- Extended browser-side atomic action execution to select, choose, check, uncheck, and upload via window.__cerberusAction.perform.\n- Switched browser resolved paths for these ops to single perform calls, removing pre-ready waits and post-success snapshots on hot paths.\n- Kept compatibility for key error semantics, including disabled select messaging, while preserving unique-target/count constraints.\n- Validated targeted behavior suites on chrome, including select/choose/upload and helper locator semantics.
