---
# cerberus-21ik
title: Refine README positioning intro and performance section
status: completed
type: task
priority: normal
created_at: 2026-03-04T12:56:54Z
updated_at: 2026-03-04T13:01:56Z
---

## Goal

Tighten top-level README messaging:
- Add a terse intro after the hero image comparing Cerberus to PhoenixTest, PhoenixTest.Playwright, Capybara/Cuprite, and Playwright.
- Clarify where Cerberus sits in the testing stack and why it is vertically integrated (correctness via parity tests).
- Move Performance Highlight further down and shorten it.
- Mention browser lane performance relative to Playwright.

## Todo

- [x] Inspect current README structure and locate hero intro and performance section
- [x] Rewrite intro section with requested comparative positioning
- [x] Move and shorten performance section with Playwright comparison
- [x] Sanity-check markdown rendering and summarize changes

## Summary of Changes

- Replaced the post-hero README intro with a terse positioning statement comparing Cerberus to PhoenixTest, PhoenixTest.Playwright, Capybara plus Cuprite, and Playwright.
- Added a concise statement about stack placement and why the library is vertically integrated, explicitly calling out cross-driver parity tests for correctness.
- Moved the performance section lower in the page, below Browser Tests.
- Shortened performance content and added explicit browser-lane comparison to Playwright-style real-browser E2E costs.

## Follow-up Todo

- [x] Strengthen top-of-page positioning copy to be more interest-catching
- [x] Refine Locators section with a brief locator definition, function composition, and sigil shorthand (e exact)
- [x] Refine Browser Tests intro around mode switching goal and browser install task
- [x] Sanity-check README flow and summarize changes

## Follow-up Summary of Changes

- Strengthened top-of-page positioning to read as a competitive value proposition while preserving explicit comparison to PhoenixTest, PhoenixTest.Playwright, Capybara plus Cuprite, and Playwright.
- Reworked Locators copy to briefly define what a locator is, emphasize composable function constructors, and show sigil shorthand with e exact.
- Reworked Browser Tests intro to center the goal: start in fast Phoenix mode and switch to browser mode for JS-dependent behavior, often by swapping session to session browser.
- Kept browser runtime setup minimal in README and highlighted the install task as CI-friendly.
