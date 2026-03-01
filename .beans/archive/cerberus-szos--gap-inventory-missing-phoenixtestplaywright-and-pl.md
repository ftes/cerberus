---
# cerberus-szos
title: 'Gap inventory: missing PhoenixTestPlaywright and Playwright features'
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:07:18Z
updated_at: 2026-02-28T07:25:11Z
parent: cerberus-ykr0
---

Prepare a concrete list of helpful PhoenixTestPlaywright and vanilla Playwright features currently missing in Cerberus, with priority and fit notes.

## Todo
- [x] Inventory current Cerberus browser capabilities.
- [x] Compare against PhoenixTest.Playwright public APIs.
- [x] Compare against high-value Playwright browser-context/page capabilities.
- [x] Produce prioritized gap list with implementation-fit notes.

## Current Cerberus browser baseline
- Supported today: browser session lifecycle (`session(:browser)`, `open_user`, `open_tab`, `switch_tab`, `close_tab`), form/navigation assertions, screenshot (`path`, `full_page`), and browser extensions (`type`, `press`, `drag`, `with_dialog`, `evaluate_js`, cookie read/write helpers).
- Runtime today is Chrome + ChromeDriver BiDi-oriented with shared process/connection architecture.

## Prioritized gap inventory
### P0 (high user value, strong architecture fit)
- Global browser context defaults:
  `viewport`, `user-agent`, and init JS hooks (`BrowserContext.addInitScript` parity).  
  Fit: high. Natural extension of existing runtime option plumbing and per-session creation.
  Tracked: `cerberus-r04r`.
- Global timeout defaults:
  BiDi command timeout, runtime HTTP/status timeout, and dialog timeout defaults.  
  Fit: high. Existing code already has local defaults/constants; centralizing config is low-risk.
  Tracked: `cerberus-qeus`, `cerberus-dh5w`, `cerberus-bflg`.
- Remote browser mode:
  Connect to remote service/browser without always launching local ChromeDriver binaries.  
  Fit: high. `Runtime` already supports `chromedriver_url`; needs first-class mode + docs/validation.
  Tracked: `cerberus-evmr`.
- Browser matrix expansion:
  Firefox support with cross-driver conformance runs.  
  Fit: medium-high. Requires capability/runtime branching but aligns with BiDi architecture.
  Tracked: `cerberus-8935`.

### P1 (important parity/features, moderate complexity)
- Cookie API parity with PhoenixTest.Playwright:
  `clear_cookies/1,2`, `add_cookies/2`, and `add_session_cookie/3` equivalents.  
  Fit: high for `clear/add_cookies`; medium for framework-specific session-cookie convenience.
  Not yet tracked as dedicated bean.
- Screenshot parity improvements:
  Element/region screenshot and richer options (format/quality/clip).  
  Fit: medium. Requires extension API additions and BiDi-level capability checks.
  Partly adjacent to `cerberus-fwox` (artifact policy), but functionality parity is separate.
- Per-test/per-module browser overrides:
  Declarative test-local browser options (viewport, UA, timeouts) with clear isolation semantics.  
  Fit: medium-high. Complements global config work.
  Tracked: `cerberus-iq1g`.

### P2 (useful, but bigger scope or less immediate)
- Network interception/stubbing parity (`route`/request mocking, response overrides).  
  Fit: medium-low for near term; high complexity and larger API design surface.
  Not yet tracked.
- Rich browser artifact tooling (trace/video/HAR capture strategy).  
  Fit: medium-low in v0; best tackled after CI/browser matrix stabilizes.
  Not yet tracked.

## Suggested execution order
1. `cerberus-r04r` (global context defaults)
2. `cerberus-qeus` + `cerberus-dh5w` + `cerberus-bflg` (timeout defaults)
3. cookie parity bean (new)
4. `cerberus-evmr` (remote mode)
5. `cerberus-8935` + `cerberus-d9r2` (matrix/policy)

## Sources
- PhoenixTest.Playwright API: https://hexdocs.pm/phoenix_test_playwright/PhoenixTest.Playwright.html
- Playwright BrowserContext API (init scripts, cookies, context options): https://playwright.dev/docs/api/class-browsercontext
- Playwright Page API (events/screenshots/download/file chooser surface): https://playwright.dev/docs/api/class-page
- Playwright browser support guide: https://playwright.dev/docs/browsers

## Summary of Changes
Built a concrete browser-feature gap inventory with priority and fit notes.
Compared current Cerberus browser APIs with PhoenixTest.Playwright and Playwright BrowserContext/Page capabilities.
Mapped P0/P1 gaps to existing beans where available and suggested execution order for upcoming work.
