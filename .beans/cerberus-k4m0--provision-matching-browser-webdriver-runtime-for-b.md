---
# cerberus-k4m0
title: Provision matching browser + WebDriver runtime for BiDi tests
status: completed
type: task
priority: normal
created_at: 2026-02-27T08:14:59Z
updated_at: 2026-02-27T15:59:44Z
parent: cerberus-sfku
---

## Scope
Establish a runnable local browser automation runtime so Cerberus can execute real WebDriver BiDi tests.

## Current Findings
- Installed pinned local Chrome for Testing binary: `145.0.7632.117` under `tmp/browser-tools`.
- Installed matching local ChromeDriver binary: `145.0.7632.117` under `tmp/browser-tools`.
- WebDriver `POST /session` succeeds with `webSocketUrl: true` using the pinned local runtime.
- Runtime provisioning and handshake are reproducible via `bin/check_bidi_ready.sh --install`.

## Acceptance
- [x] Browser and driver major versions match (or equivalent supported pairing).
- [x] `POST /session` succeeds with `webSocketUrl: true` capability.
- [x] returned capabilities include a non-empty BiDi `webSocketUrl`.
- [x] handshake check documented in README/dev docs.

## Done When
- [x] local command/script can validate BiDi readiness in one step.
- [x] Cerberus browser-driver implementation bean can proceed unblocked.

## Architectural Decision (2026-02-27)
- Browser runtime model for BiDi tests: single shared browser process.
- Connection model: single shared BiDi connection per worker/runtime, multiplexed by command id.
- Isolation model: one isolated browser context per test (not merely separate tabs).

## Protocol Direction Notes (2026-02-27)
- Recommendation: keep WebDriver BiDi as Cerberus primary protocol; do not switch core architecture to CDP.
- Rationale: CDP remains Chromium-specific and its tip-of-tree protocol is explicitly unstable; WebDriver BiDi remains a W3C Working Draft but is the standardization path and is now broadly implemented in current browser/tooling stacks.
- Isolation recommendation: keep isolated browser context per test as default; avoid module-shared context except for explicitly stateful performance suites.
- Cost note: context creation is generally low-overhead compared to browser launch; actual Cerberus-specific timings should be benchmarked after runtime provisioning is unblocked.

## Summary of Changes
- Implemented pinned local Chrome/ChromeDriver provisioning under `tmp/browser-tools`.
- Added strict major/build parity checks plus BiDi handshake validation in `bin/check_bidi_ready.sh`.
- Updated repository env wiring and README docs to use local pinned browser runtime by default.
- Verified successful `POST /session` handshake with non-empty BiDi `webSocketUrl`.
