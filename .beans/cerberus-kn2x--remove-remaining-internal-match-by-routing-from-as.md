---
# cerberus-kn2x
title: Remove remaining internal match_by routing from assertions
status: todo
type: task
created_at: 2026-03-08T08:50:46Z
updated_at: 2026-03-08T08:50:46Z
parent: cerberus-iyju
---

## Context

Public match_by has been removed, but internal assertion plumbing still routes through match_by-style discriminators and generic selector or value helpers. That keeps older assertion architecture alive longer than necessary.

## Scope

Move assertion internals toward locator-driven routing while preserving existing external behavior.

## Work

- [ ] Inventory internal match_by fields, helpers, and normalization paths in assertions and drivers
- [ ] Remove assertion normalization that translates locators into generic text-matching requests where locator-native handling can be used instead
- [ ] Collapse browser selector or value helpers that still branch on match_by atoms
- [ ] Simplify static and live assertion value extraction so locator kind drives matching directly
- [ ] Keep option validation and failure messages coherent after the refactor
- [ ] Run targeted assertion suites, then precommit and full tests
