---
# cerberus-n1uq
title: Add mixed naming-source parity fixtures across browser, static, and live
status: todo
type: task
created_at: 2026-03-08T08:50:46Z
updated_at: 2026-03-08T08:50:46Z
parent: cerberus-iyju
---

## Context

Browser, static, and live drivers can still drift when an element has more than one plausible naming source. We need fixed parity fixtures that encode those combinations and make intended behavior explicit.

## Scope

Add fixture-backed parity cases for headings, links, buttons, and image-like elements whose names come from combinations of text, aria-label, aria-labelledby, and nested content.

## Example Cases

- Link with visible text plus aria-label and aria-labelledby
- Button with visible text plus nested icon or image alt text, aria-labelledby, and aria-label
- Heading whose text differs from its labelled-by content, including extra badge or hidden text
- Svg role img and img nodes with explicit labels versus visible surrounding text
- Button or link wrappers around images whose name may come from nested image alt text versus explicit labels

## Work

- [ ] Add shared fixture HTML and LiveView markup for mixed naming-source cases
- [ ] Add browser, static, and live parity assertions for each case
- [ ] Cover multi-id labelled-by references and mixed hidden or visible naming-source combinations in the shared fixtures
- [ ] Document intended winner or fallback behavior per case
- [ ] Keep fixtures reusable by both helper-level and oracle-style tests
