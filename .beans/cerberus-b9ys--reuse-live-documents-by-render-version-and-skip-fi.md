---
# cerberus-b9ys
title: Reuse live documents by render version and skip first refresh
status: completed
type: task
priority: normal
created_at: 2026-03-10T06:08:41Z
updated_at: 2026-03-10T06:20:58Z
---

Make the live driver reuse the current LazyHTML snapshot by render version, build documents from LiveViewClient.html_document instead of render plus parse, and execute the first live action or assertion resolve against the existing snapshot before forcing any refresh.

## Summary of Changes

Changed the live driver to reuse parsed live documents by render version and avoid a forced refresh before the first live action resolve attempt. The live session now stores render_version, with_latest_document reuses the existing LazyHTML snapshot when the render version is unchanged, and refresh_live_document uses the LiveView tree path first instead of render plus parse. Live actions no longer call with_latest_document before entering wait_for_live_actionable, so the first resolve runs against the existing snapshot and only refreshes after retryable failures or awaited progress. Adjusted nested child LiveView document refresh to extract the current child subtree from the tree so within on nested live views still resolves against the child DOM. Also fixed two unrelated typespec issues in Cerberus.Browser and Cerberus so the change could compile and run.

Verification:
- source .envrc && PORT=4904 MIX_ENV=test mix test test/cerberus/live_nested_scope_behavior_test.exs test/cerberus/live_select_regression_test.exs test/cerberus/live_checkbox_behavior_test.exs test/cerberus/form_actions_test.exs
- source .envrc && PORT=4907 MIX_ENV=test mix do format + precommit + test + test --only slow
- EV2 preserved live comparison:
  - notifications_cerberus_test warm rerun: 13.4s
  - notifications_test warm rerun: 2.4s
