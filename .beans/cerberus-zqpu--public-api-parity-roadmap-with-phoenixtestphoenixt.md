---
# cerberus-zqpu
title: Public API parity roadmap with PhoenixTest/PhoenixTest.Playwright
status: todo
type: feature
priority: normal
created_at: 2026-02-27T11:00:34Z
updated_at: 2026-02-27T11:59:37Z
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
