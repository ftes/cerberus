---
# cerberus-k4m0
title: Provision matching browser + WebDriver runtime for BiDi tests
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T08:14:59Z
updated_at: 2026-02-27T09:32:09Z
parent: cerberus-sfku
---

## Scope
Establish a runnable local browser automation runtime so Cerberus can execute real WebDriver BiDi tests.

## Current Findings
- Installed Chrome binary: `145.0.7632.117`
- Installed ChromeDriver binary: `146.0.7680.31`
- Session creation fails due strict major-version mismatch.
- Network/DNS is currently unavailable in this execution environment, so fetching a matching driver/browser here is blocked.

## Acceptance
- [ ] Browser and driver major versions match (or equivalent supported pairing).
- [ ] `POST /session` succeeds with `webSocketUrl: true` capability.
- [ ] returned capabilities include a non-empty BiDi `webSocketUrl`.
- [ ] handshake check documented in README/dev docs.

## Done When
- [ ] local command/script can validate BiDi readiness in one step.
- [ ] Cerberus browser-driver implementation bean can proceed unblocked.

## Architectural Decision (2026-02-27)
- Browser runtime model for BiDi tests: single shared browser process.
- Connection model: single shared BiDi connection per worker/runtime, multiplexed by command id.
- Isolation model: one isolated browser context per test (not merely separate tabs).

## Protocol Direction Notes (2026-02-27)
- Recommendation: keep WebDriver BiDi as Cerberus primary protocol; do not switch core architecture to CDP.
- Rationale: CDP remains Chromium-specific and its tip-of-tree protocol is explicitly unstable; WebDriver BiDi remains a W3C Working Draft but is the standardization path and is now broadly implemented in current browser/tooling stacks.
- Isolation recommendation: keep isolated browser context per test as default; avoid module-shared context except for explicitly stateful performance suites.
- Cost note: context creation is generally low-overhead compared to browser launch; actual Cerberus-specific timings should be benchmarked after runtime provisioning is unblocked.
