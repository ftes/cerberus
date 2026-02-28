# Browser Support Policy

This document defines Cerberus browser support tiers for WebDriver BiDi and the constraints required for promotion.

## Current Baseline

Cerberus currently has one official browser target:

- Chrome/Chromium via ChromeDriver BiDi.

This is the only target validated by conformance tests and CI today.

Current runtime assumptions are Chrome-specific:

- WebDriver session handshake uses `browserName: "chrome"`.
- Capabilities use `goog:chromeOptions`.
- Local managed runtime expects Chrome and ChromeDriver binaries (`CHROME`, `CHROMEDRIVER`).
- Remote runtime mode (`webdriver_url`) connects to a pre-running WebDriver endpoint and skips local browser/chromedriver launch.

## Support Tiers

### Tier 1: Officially Supported

- Maintained in CI.
- Covered by browser conformance suites and shared API examples.
- Included in setup docs with deterministic local install instructions.

Current Tier 1 browser:

- Chrome/Chromium (ChromeDriver + BiDi).

### Tier 2: Planned/Experimental

- Actively being implemented, but not yet guaranteed in CI.
- May be available behind explicit opt-in APIs or runtime settings.

Current Tier 2 targets:

- Firefox (`session(:firefox)`), currently experimental.

### Tier 3: Unsupported

- No compatibility guarantees.
- No CI coverage.
- Community experiments are allowed, but breakage is expected.

Current Tier 3 targets:

- Edge as a first-class target (Chromium engine overlap exists, but no official adapter/CI policy yet).
- Safari/WebKit (no Cerberus runtime target yet).

## Admission Criteria For Tier 1

A browser moves to Tier 1 only when all conditions are met:

- Stable runtime handshake and startup strategy (local and CI).
- Full conformance coverage across shared Cerberus APIs.
- Browser-only extensions (`Cerberus.Browser.*`) have documented behavior and known limitations.
- Multi-user and multi-tab isolation semantics match Cerberus contracts.
- Setup documentation is complete and reproducible.

## Explicitly Separate Work

This policy document does not implement:

- global timeout/screenshot default knobs (`cerberus-kmpz`, `cerberus-qeus`, `cerberus-bflg`, `cerberus-dh5w`, `cerberus-fwox`).
