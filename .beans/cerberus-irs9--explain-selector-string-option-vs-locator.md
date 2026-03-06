---
# cerberus-irs9
title: Explain selector string option vs locator
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:59:21Z
updated_at: 2026-03-06T09:02:03Z
---

## Goal\n\nExplain why some public APIs accept selector as string keyword option instead of locator, and why selector option exists.\n\n## Todo\n\n- [x] Inspect current API docs and types around selector options\n- [x] Inspect implementation paths that consume selector\n- [x] Provide concise rationale and tradeoffs to user\n

## Summary of Changes\n\n- Reviewed locator and option contracts in Cerberus, Cerberus.Options, and Cerberus.Locator to confirm selector is defined as a CSS-string filter, not a full locator input.\n- Traced normalization and dispatch in Cerberus.Assertions and Cerberus.Driver.LocatorOps showing locators are primary and selector is merged as a narrowing constraint.\n- Traced driver consumption in live, browser, and html modules to confirm string selectors are required by underlying APIs Phoenix.LiveViewTest.element/2 and document.querySelector, and used for deterministic disambiguation in duplicate-label and duplicate-control scenarios.\n
