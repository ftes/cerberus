---
# cerberus-j8e0
title: Compare Playwright Capybara Cypress docs
status: completed
type: task
priority: normal
created_at: 2026-03-09T18:36:18Z
updated_at: 2026-03-09T18:39:15Z
---

## Goal

Compare current documented support in Playwright, Capybara, and Cypress for locators, multi-session handling, multi-window handling, and dialogs.

## Todo

- [x] Gather current official docs for Playwright
- [x] Gather current official docs for Capybara
- [x] Gather current official docs for Cypress
- [x] Summarize differences with source links

## Summary of Changes

- Gathered current official docs for Playwright, Capybara, and Cypress covering locators, isolated sessions, windows/tabs, and dialogs.
- Confirmed that Playwright and Capybara both document first-class multi-session and multi-window support, while Cypress documents single-browser control with plugin-based tab workarounds.
- Confirmed that dialog support is unified and rich in Playwright, driver-dependent but explicit in Capybara, and event/stub based in Cypress rather than a unified dialog object API.
