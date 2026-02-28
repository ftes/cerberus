---
# cerberus-xou2
title: Implement static upload support for :phoenix sessions
status: completed
type: bug
priority: normal
created_at: 2026-02-28T17:46:44Z
updated_at: 2026-02-28T18:15:27Z
parent: cerberus-it5x
---

Cerberus upload currently fails on static routes (static driver upload returns not supported; live driver on static routes also errors). This blocks full source API parity for PhoenixTest upload/3 in migration rows.\n\nScope:\n- Implement upload support for static driver form/file inputs.\n- Ensure :phoenix session behavior for static routes supports upload end-to-end.\n- Add cross-driver conformance coverage for static + live upload behavior as applicable.\n\nAcceptance:\n- upload/3 works on static routes in :phoenix mode.\n- Migration parity row pt_upload can run without route-specific workaround semantics.\n- Conformance tests pass for upload coverage.

## Summary of Changes
- Implemented static upload support in Cerberus.Driver.Static by resolving file inputs by label, storing Plug.Upload form state, and surfacing file/path errors as assertion failures.
- Extended static submit handling to support non-GET form methods via Conn.follow_request/5, preserving redirect handling and static-live transitions.
- Added static-route upload handling to Cerberus.Driver.Live static mode branch for parity.
- Updated HTML form field allowlist logic so file input names are preserved for submit payload pruning.
- Added static upload fixture routes/pages and conformance coverage in test/core/static_upload_behavior_test.exs.
- Added migration fixture upload scenario pt_upload with fixture file and wired the row into migration verification.
- Updated migration verification matrix docs to mark upload row unblocked and implemented.
