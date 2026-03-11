---
# cerberus-b3o3
title: Investigate EV2 live toast parity gap
status: completed
type: task
priority: normal
created_at: 2026-03-11T08:50:09Z
updated_at: 2026-03-11T11:02:32Z
---

Compare PhoenixTest and Cerberus behavior on the remaining EV2 live toast parity failures in project_setup_cerberus_test.exs and subscriptions_cerberus_test.exs. Identify the exact behavioral difference that makes PhoenixTest pass while Cerberus fails, with concrete code-path evidence.

## Findings

- The remaining EV2 failures are live redirect + flash parity failures, not browser toast timing issues.
- PhoenixTest live assertions operate on `current_operation.html`, but the more important divergence is redirect handling.
- PhoenixTest's live `maybe_redirect/2` handles `{:error, {kind, %{to: path}}}` by calling `follow_redirect(...)` once and then reusing the resulting live session/view.
- Cerberus `follow_live_redirect_result/4` currently calls `Phoenix.LiveViewTest.__follow_redirect__/4` and then issues an extra `Conn.follow_get(...)` before rebuilding the live session. That likely advances past the flash-bearing redirected response and explains why redirecting success toasts are missing in Cerberus while PhoenixTest still sees them.
- Avoiding the post-action HTML string parse and using the current LiveView tree directly kept Cerberus tests green, but did not fix the downstream toast failures; the extra redirect-follow step is the more plausible root cause.

- Tested the stricter LiveViewTest-style redirect flow hypothesis: removing the extra `follow_get` and then doing a single-step live connect did not fix the EV2 failures. Reverted that experiment.
- Therefore the remaining parity gap is not explained solely by Cerberus double-following redirects.
- The deeper mismatch is still between what PhoenixTest exposes to the next assertion after a redirecting action and what Cerberus keeps as the current live snapshot.

## Summary of Changes

- Identified the real live toast parity bug as mixed live redirect handling on click actions, not browser timing or HTML parsing.
- Fixed live click redirect normalization so metadata-driven live redirects use full redirect maps instead of bare path strings.
- Fixed live session rebuilding after live redirects/navigations to derive current_path from the connected LiveView URL instead of patch-only detection.
- Added focused regression coverage for JS navigate and JS dispatch+push live button clicks so future regressions are not masked inside larger tests.
- Verified the full Cerberus suite is green again and the EV2 Cerberus-selected subset is reduced to the separate subscriptions disabled-field parity bug tracked in cerberus-4tyh.
