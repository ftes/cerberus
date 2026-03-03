---
# cerberus-hg2h
title: Slim remaining Cerberus and Browser facade hotspots
status: completed
type: task
priority: normal
created_at: 2026-03-03T20:24:28Z
updated_at: 2026-03-03T20:42:46Z
---

## Goal
Finish the remaining façade slimming work requested by user.

## Todo
- [x] Delegate remaining Locator DSL shaping (role/closest) to Locator module
- [x] Move path assertion timeout/default and dispatch selection behind driver callbacks
- [x] Deduplicate browser session constructors in Cerberus
- [x] Collapse repetitive browser-only guard/validate/unsupported scaffolding in Cerberus.Browser
- [x] Unify evaluate_js implementation path in Cerberus.Browser
- [x] Run format, focused tests, and precommit

## Summary of Changes
- Added Locator-level role and closest helpers and switched Cerberus DSL role/closest to delegate there.
- Added driver callbacks for default assert timeout and path assertion execution; Cerberus now delegates path orchestration to drivers.
- Deduplicated Cerberus browser session constructors via private new_browser_session helper.
- Refactored Cerberus.Browser repetitive browser-only validation/unsupported scaffolding into a shared helper.
- Unified Browser.evaluate_js value retrieval path and callback form handling via shared evaluate_js_value helper.
- Validation: mix format, focused timeout/path/within/browser/locator suites, and mix precommit.
