---
# cerberus-drmq
title: Assess locator model strategy vs Playwright migration
status: completed
type: task
priority: normal
created_at: 2026-03-05T20:10:41Z
updated_at: 2026-03-05T20:11:46Z
---

## Goal
Recommend whether Cerberus should adopt a standard locator model and/or switch to Playwright for API maturity.

## Todo
- [x] Inspect current Cerberus locator architecture and pain points in code
- [x] Compare likely benefits/costs of standard locator model alignment
- [x] Compare likely benefits/costs of switching backend to Playwright
- [x] Provide recommendation with practical next steps

## Summary of Changes
Reviewed locator architecture and browser helper implementations to assess whether Cerberus should switch models. Confirmed locator AST and composition semantics are central to cross-driver parity and diagnostics. Evaluated Playwright migration tradeoffs against this architecture and existing compatibility fixtures; recommendation is to keep Cerberus locator semantics, standardize a strict portable subset, and avoid full backend switch to Playwright for now.
