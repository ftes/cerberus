---
# cerberus-5v8o
title: Expand locator oracle coverage for aria-labelledby and accessible-name cases
status: todo
type: task
created_at: 2026-03-08T08:50:46Z
updated_at: 2026-03-08T08:50:46Z
parent: cerberus-iyju
---

## Context

The larger locator oracle suite does not yet stress aria-labelledby-heavy or mixed accessible-name cases. Adding those cases first will make later semantic changes safer and easier to evaluate.

## Scope

Grow the oracle corpus with accessible-name-focused cases that compare Cerberus behavior against the browser oracle at the locator level.

## Work

- [ ] Add aria-labelledby cases for form controls, links, buttons, headings, and image roles
- [ ] Add mixed-source cases where visible text conflicts with aria-label or labelled-by text
- [ ] Cover multi-id labelled-by references and partial missing-reference scenarios
- [ ] Assert both positive matches and non-matches for exact and regex locators where relevant
- [ ] Keep cases organized so future role-expansion work can reuse them
- [ ] Run the locator oracle suite plus targeted parity tests
