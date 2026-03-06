---
# cerberus-hrle
title: Evaluate await_liveview_connected API
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:49:29Z
updated_at: 2026-03-06T08:53:05Z
---

Assess whether Cerberus should add Cerberus.Browser.await_liveview_connected for LiveView and LiveComponent readiness, based on current code and PhoenixTest Playwright guidance.

## Summary of Changes

- Reviewed Cerberus browser readiness internals (, action settle, assertion wait loops) and confirmed there is no public  helper.
- Checked PhoenixTest Playwright docs section : recommendation is to explicitly wait with ; for LiveComponent use a custom connected marker and  on that selector.
- Recommendation: do not add a dedicated API yet because  already covers both cases with fewer public surface additions and clearer intent per component.

## Summary of Changes (Corrected)

- Reviewed Cerberus browser readiness internals: await_ready pipeline, action settle behavior, and assertion wait loops.
- Confirmed there is no public Cerberus.Browser.await_liveview_connected helper today.
- Checked PhoenixTest Playwright docs section liveview-not-connected, which recommends explicit assert_has waits: body .phx-connected for LiveView and a component-specific connected marker for LiveComponent.
- Recommendation: do not add a dedicated API yet; prefer assert_has-based waits to keep the public surface small while covering both use cases.
