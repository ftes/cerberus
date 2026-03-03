---
# cerberus-9h1b
title: Add testid sigil and align locator docs/examples
status: completed
type: feature
priority: normal
created_at: 2026-03-02T12:17:49Z
updated_at: 2026-03-02T12:32:53Z
---

Implement ~l testid modifier (t), document all sigils and rules, and update docs/moduledoc/function @doc examples to use sigils where possible.

## Summary of Changes

- Added ~l testid sigil support with default exact matching and explicit validation for non-empty testid values.
- Extended locator sigil parser/error messages and added tests for valid/invalid testid sigil combinations.
- Updated docs to document all supported locator sigils (e, i, r, c, t) and their rules.
- Converted docs/examples to prefer locator sigils where practical across README, getting-started guide, cheatsheet, moduledoc, and function docs.
- Added parity coverage for testid sigil usage in cross-driver locator behavior tests.
- Installed latest managed browser/runtime binaries via project scripts and verified with targeted tests plus mix precommit.
