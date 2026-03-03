---
# cerberus-dsr0
title: Adopt lightweight Playwright-style browser action semantics
status: completed
type: feature
priority: normal
created_at: 2026-03-03T11:30:30Z
updated_at: 2026-03-03T22:22:08Z
---

Decision: move browser driver to lightweight Playwright-like semantics for actions and waits.

Implemented scope:
- [x] Resolve locator and perform action atomically in browser helper APIs on hot action paths.
- [x] Keep actionability checks and strict target semantics in browser action execution.
- [x] Remove global pre-action readiness waits from core hot paths where safe.
- [x] Remove post-action success snapshot dependence from core hot paths.
- [x] Change link click behavior to literal DOM click semantics first.
- [x] Move browser path assertions to a single in-browser wait loop.
- [x] Validate behavior on chrome browser suites.

## Summary of Changes
- Browser actions are now driven by a lightweight in-browser perform flow with strict diagnostics.
- Link click behavior aligns with DOM click semantics, including intercepted and prevented navigation behavior.
- Browser path assertions use a browser-side polling loop and shared path assertion formatting.
- Scope was explicitly narrowed to implemented chrome-focused semantics and marked complete.
