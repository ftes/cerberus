---
# cerberus-utgw
title: Compare EV2 migrated Cerberus tests against original PhoenixTest and Playwright runtimes
status: completed
type: task
priority: normal
created_at: 2026-03-09T18:40:23Z
updated_at: 2026-03-09T18:42:55Z
---

Identify EV2 migrated Cerberus tests that still have original PhoenixTest or Playwright counterparts, run the original and migrated versions sequentially using mix test reported times, and summarize the runtime differences.

## Summary of Changes

Identified the only three EV2 test pairs that still have a direct original-versus-Cerberus side-by-side file layout: project_form_feature, register_and_accept_offer, and project_settings_live notifications. Ran each original file and its Cerberus counterpart sequentially, using mix test reported times rather than shell runtime.

Measured results:
- project_form_feature: Playwright 5.7s vs Cerberus 16.6s
- register_and_accept_offer: Playwright 4.4s vs Cerberus 19.6s
- notifications: PhoenixTest 2.2s vs Cerberus 13.5s

This leaves Cerberus roughly 2.9x slower on project_form_feature, 4.5x slower on register_and_accept_offer, and 6.1x slower on the notifications file in EV2.
