---
# cerberus-yx1n
title: Refine CI lane partitioning and shared service config
status: completed
type: task
created_at: 2026-02-28T19:37:19Z
updated_at: 2026-02-28T19:45:07Z
parent: cerberus-it5x
---

Follow-up on CI optimization: avoid duplicated Postgres service declarations where possible and switch lane test selection to tag-based include/exclude (no file-path targeting).

## Todo
- [x] Audit current test tags and lane overlap
- [x] Introduce lane tags for migration verification/doc examples if missing
- [x] Update CI workflow to use tag-based test selection with unique subsets
- [x] Reduce/centralize duplicated Postgres config as far as GitHub Actions allows
- [x] Run format/precommit and record change summary

## Summary of Changes

- Added module tag `:migration_verification` to the migration verification test module so CI can select it via `--only migration_verification`.
- Added module tag `:remote_webdriver` to the remote webdriver behavior test module so CI can isolate that lane via `--only remote_webdriver`.
- Reworked `.github/workflows/ci.yml` back to a single `CI` job with one shared Postgres service and one shared setup/caching sequence.
- Replaced file-path test selection with tag-based partitioning:
  - `mix test --only conformance --exclude browser`
  - `mix test --only migration_verification`
  - `mix test --only conformance --only browser --exclude remote_webdriver`
  - `mix test.websocket --only remote_webdriver`
- Validation performed: `mix format`, `mix precommit`, YAML parse check for workflow.
