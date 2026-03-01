---
# cerberus-9cwo
title: Add locator oracle harness tests
status: in-progress
type: task
created_at: 2026-03-01T15:57:49Z
updated_at: 2026-03-01T15:57:49Z
---

Create dedicated tests that compare locator matching in Elixir parsing/matching and browser JS matching against the same HTML snippets, covering edge cases without full live/browser route flows.

## Todo
- [ ] Inspect existing browser helper APIs for setting HTML snippets and extracting matches
- [ ] Implement a locator oracle harness test module for static-vs-browser parity on snippets
- [ ] Cover edge cases (whitespace, visibility, exact/inexact, link/button/label/css/role mappings)
- [ ] Add follow-up beans for missing locator-engine improvements (role/label/placeholder/alt/title, count/position filters, chaining, state filters)
- [ ] Run format and targeted tests
