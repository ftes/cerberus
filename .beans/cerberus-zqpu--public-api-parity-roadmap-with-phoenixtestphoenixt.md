---
# cerberus-zqpu
title: Public API parity roadmap with PhoenixTest/PhoenixTest.Playwright
status: completed
type: feature
priority: normal
created_at: 2026-02-27T11:00:34Z
updated_at: 2026-02-28T06:40:10Z
parent: cerberus-ktki
---

## Scope
Track grouped API parity work using PhoenixTest and PhoenixTest.Playwright as references for ergonomic feature-test flows.

## Reference Surface (from docs)
- PhoenixTest core flow + forms: visit, click_link, click_button, fill_in, select, choose, check, uncheck, submit, within, upload
- PhoenixTest assertions/navigation: assert_has/refute_has, assert_path/refute_path
- PhoenixTest.Playwright browser extensions: screenshot, type, press, drag, with_dialog, cookie/session-cookie helpers, trace step annotations
- PhoenixTest.Playwright selector helpers: text/role/label/link/button/etc composition

## Goal
Prioritize grouped slices that keep Cerberus API coherent while adding missing capabilities in vertical increments.

## Test Placement Policy
- Replicas derived from PhoenixTest.StaticTest belong in the test_all harness.
- Replicas derived from PhoenixTest.LiveTest belong in the live + browser harness, but only for behavior that is LiveView-specific.
- Replicas derived from PhoenixTest.Playwright belong in the browser-only harness.
- Avoid duplicate Live-only replicas when the corresponding static test already runs across static+live in our harness.

## Summary of Changes
- Completed parity slices across interaction/form flows, navigation/path assertions, scoped flows, locator helpers/sigils, and static/live/browser adapter behavior.
- Replicated key phoenix_test LiveView edge semantics (phx-change payload/order, phx-trigger-action, button/form ownership, timeout/watcher behavior, connect params across navigation, upload edge cases).
- Added and expanded cross-driver conformance coverage (including browser-oracle and multi-user/multi-tab scenarios) and browser-only extension parity (screenshot, keyboard/drag/dialog/cookie helpers).
- Folded mined upstream phoenix_test issues into concrete Cerberus bug/task beans and resolved them under this feature umbrella.
- Aligned docs and API guidance with implemented parity behavior for the v0 slice.
