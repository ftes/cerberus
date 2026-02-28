---
# cerberus-2zwr
title: Rename generic oracle/conformance test names
status: completed
type: task
priority: normal
created_at: 2026-02-28T14:33:23Z
updated_at: 2026-02-28T14:35:23Z
---

Rename test/core files and module names to behavior-first naming (remove generic 'oracle' and 'conformance' from file/module/test names where practical) while keeping conformance tags/filters intact.

## Summary of Changes
- Renamed generic test file names in test/core from *conformance*/*oracle* to behavior-first names.
- Updated corresponding test module names to remove Conformance/Oracle naming.
- Renamed mismatch fixture test descriptions from oracle-focused wording to parity-focused wording.
- Kept existing conformance tags and driver selection behavior unchanged.
