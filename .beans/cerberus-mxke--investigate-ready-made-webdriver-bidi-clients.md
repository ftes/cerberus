---
# cerberus-mxke
title: Investigate ready-made WebDriver BiDi clients
status: completed
type: task
priority: normal
created_at: 2026-03-05T19:51:18Z
updated_at: 2026-03-05T19:53:59Z
---

## Goal
Find maintained WebDriver BiDi client implementations we could adopt instead of building a custom client, including non-JS options suitable for NIF interop.

## Todo
- [x] Gather current maintained BiDi clients from primary sources
- [x] Evaluate fit for Cerberus (language, maturity, NIF friendliness)
- [x] Share recommendation with tradeoffs and links

## Summary of Changes
Researched current WebDriver BiDi client options from Selenium docs, WebdriverIO, Rust and .NET BiDi client repos, and Hex ecosystem packages. Evaluated maturity and integration fit for NIF/Port usage, and prepared a recommendation prioritizing maintained clients over building a custom protocol stack.
