---
# cerberus-lvxx
title: Adopt ExUnit tmp_dir in tests
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:30Z
updated_at: 2026-02-28T15:11:53Z
---

## Goal\n\nUse ExUnit tmp_dir context in relevant tests (including migration verification) instead of ad-hoc temp paths where practical.\n\n## Checklist\n\n- [x] Audit current tmp directory usage in tests\n- [x] Migrate eligible tests to tmp_dir context\n- [x] Run mix format and targeted tests

## Summary of Changes

- Replaced ad-hoc temporary directory setup in migration verification and migration task tests with ExUnit tmp_dir tagging.
- Migrated individual tests that used System.tmp_dir!() to ExUnit tmp_dir context via :tmp_dir tags (runtime, timeout defaults, public API browser screenshot, browser extensions, screenshot behavior).
- Removed all remaining System.tmp_dir!() calls from test/.
- Ran mix format and targeted verification tests, including browser-tagged tests outside sandbox.
