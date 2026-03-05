---
# cerberus-h1vx
title: Assess locator flexibility in Selenium vs WebdriverIO
status: completed
type: task
priority: normal
created_at: 2026-03-05T19:58:24Z
updated_at: 2026-03-05T19:58:48Z
---

## Goal
Determine whether Selenium or WebdriverIO impose Playwright-like locator constraints for custom locator models.

## Todo
- [x] Confirm documented selector customization/extensibility points
- [x] Provide recommendation for Cerberus custom locator architecture

## Summary of Changes
Compared Selenium and WebdriverIO selector extensibility against Playwright-style constraints. Confirmed WebdriverIO supports explicit custom locator strategies (addLocatorStrategy/custom$) and protocol-level command access; Selenium supports standard locator strategies, JS locator functions in JS bindings, and server-side custom locator extension points.
