---
# cerberus-k8zs
title: Require explicit locators in public API and explicit text sigil mode
status: completed
type: feature
priority: normal
created_at: 2026-03-04T08:44:52Z
updated_at: 2026-03-04T09:16:07Z
---

Disallow string shorthand arguments in public action/assert APIs and require explicit locator inputs. Enforce explicit text sigil matching mode (e or i) for plain text ~l locators. Update Igniter migrator to convert string args in action/assert operations to explicit locator sigils with explicit text mode.

Scope:
- [x] Identify and remove string shorthand acceptance in public action/assert operations
- [x] Enforce explicit text mode in ~l sigil (require e or i for plain text form)
- [x] Update operation docs and examples for explicit locators
- [x] Extend Igniter migration to rewrite string args to ~l"..."e or ~l"..."i as appropriate
- [x] Add/update tests for API validation and migrator rewrites
- [x] Run format and precommit

## Summary of Changes
- Enforced explicit locator-only public action/assert API usage by tightening function heads in Cerberus.Assertions with locator guards and removing dedicated legacy string/regex handling branches.
- Enforced explicit text sigil mode for plain text sigils in Cerberus.Locator, requiring an explicit exact or inexact mode.
- Updated migration task canonicalization so action/assert locator arguments are rewritten to explicit locators:
  string literals become explicit locator sigils,
  regex literals become text keyword locators,
  dynamic expressions become text keyword locators.
- Updated docs and examples (README, getting-started, cheatsheet) to use explicit locators and explicit text sigil modes.
- Updated/expanded tests for strict locator inputs and migration rewrite outputs; fixed affected test modules to remove legacy shorthand usage and keep browser/live/static parity behavior.
- Validation:
  ran format and precommit successfully,
  ran browser-inclusive changed-suite tests with 241 passing tests and 2 excluded tests.
