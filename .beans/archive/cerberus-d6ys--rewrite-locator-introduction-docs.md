---
# cerberus-d6ys
title: Rewrite locator introduction docs
status: completed
type: task
priority: normal
created_at: 2026-03-03T10:08:28Z
updated_at: 2026-03-03T10:12:42Z
---

Restructure locator docs with a simple-first introduction and practical Phoenix/LiveView examples, then brief advanced composition guidance.\n\nScope:\n- [x] Audit current locator docs in README/getting-started/cheatsheet\n- [x] Rewrite getting-started locator section as primary introduction\n- [x] Rewrite cheatsheet locator section for quick lookup\n- [x] Align README locator examples with new canonical/simple narrative\n- [x] Run format + precommit and commit docs + bean

## Summary of Changes

Rewrote locator documentation to teach a simple-first strategy for Phoenix/LiveView tests, then progressively introduce advanced composition.

Updated docs:
- docs/getting-started.md
  - Added a dedicated "Locator Basics (Phoenix/LiveView First)" section.
  - Emphasized default selector strategy (label/role/text first, then testid/css).
  - Added practical examples for forms, scoped interaction, and disambiguation.
  - Kept advanced composition brief and separate.
- docs/cheatsheet.md
  - Reworked locator section into a decision-oriented quick reference with common-case table.
  - Grouped helper constructors, role aliases, sigil syntax, and advanced composition hints.
- README.md
  - Reframed locator quick look to match simple-first narrative and canonical helpers.
  - Added concise advanced composition summary and pointer to getting-started guide.

Validation:
- source .envrc && mix format
- source .envrc && mix precommit
