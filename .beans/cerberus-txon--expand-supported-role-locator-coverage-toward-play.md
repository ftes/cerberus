---
# cerberus-txon
title: Expand supported role locator coverage toward Playwright
status: todo
type: feature
created_at: 2026-03-08T08:50:46Z
updated_at: 2026-03-08T08:50:46Z
parent: cerberus-iyju
---

## Context

Cerberus currently supports only a bounded subset of Playwright-style roles. Common interactive, structural, and landmark roles are still missing, which limits migration parity and forces tests onto css or text fallbacks.

## Scope

Add the next practical role slice with shared semantics across locator parsing, static/live matching, browser matching, docs, and tests.

## Candidate Roles

- dialog, alertdialog, alert, status, progressbar, slider, separator
- option, list, listitem, table, row, cell, columnheader, rowheader, grid
- tree, treeitem, tabpanel
- main, navigation, banner, contentinfo, complementary, form, region, search

## Work

- [ ] Decide the next supported role batch and document any exclusions
- [ ] Extend public role validation and typespecs
- [ ] Add role selectors and matching in browser, static HTML, and LiveView drivers
- [ ] Add fixtures and assertions covering both explicit role attributes and implicit HTML mappings where supported
- [ ] Update docs and cheatsheets with the broadened role list
- [ ] Run targeted locator suites and browser coverage for the new roles
