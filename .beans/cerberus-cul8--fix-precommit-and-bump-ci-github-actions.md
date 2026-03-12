---
# cerberus-cul8
title: Fix precommit and bump CI GitHub Actions
status: completed
type: bug
priority: normal
created_at: 2026-03-12T12:48:53Z
updated_at: 2026-03-12T12:55:00Z
---

## Goal

Fix the current precommit failure and update .github/workflows/ci.yml to the latest needed GitHub Action major versions.

## Todo

- [x] reproduce the current precommit failure locally
- [x] patch the code or config causing the failure
- [x] bump ci.yml GitHub Actions versions as needed
- [x] run format and targeted verification
- [x] add summary and mark completed

## Summary of Changes

- Refactored browser transient retry helpers to satisfy Credo and Dialyzer without changing retry behavior.
- Flattened direct Firefox runtime startup into smaller helpers to clear nested control-flow checks.
- Bumped CI workflow actions to actions/checkout v6, actions/cache v5, and erlef/setup-beam v1.9.
- Verified with targeted runtime and browser extension tests plus PORT=4127 mix precommit.
