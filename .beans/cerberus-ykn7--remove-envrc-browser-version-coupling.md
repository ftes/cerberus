---
# cerberus-ykn7
title: Remove .envrc browser version coupling
status: completed
type: task
priority: normal
created_at: 2026-03-12T09:28:39Z
updated_at: 2026-03-12T09:29:30Z
---

Use stable tmp/* browser paths in .envrc instead of versioned env vars, and update CI browser cache keys to track install task/source files instead of .envrc version exports. Verify focused behavior after the cleanup.

## Summary of Changes

- simplified `.envrc` to export stable managed-runtime links (`tmp/chrome-current`, `tmp/chromedriver-current`, `tmp/firefox-current`) instead of version-derived paths
- removed the CI step that loaded browser version env vars from `.envrc`
- changed the browser runtime cache key in `ci.yml` to hash the browser installer scripts and Mix install source files instead of env-provided versions
- verified the new `.envrc` exports and reran the focused install-task tests successfully
