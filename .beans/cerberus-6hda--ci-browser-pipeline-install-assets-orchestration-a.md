---
# cerberus-6hda
title: 'CI browser pipeline: install, assets, orchestration, and mix tasks'
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T07:07:19Z
updated_at: 2026-02-28T07:28:06Z
parent: cerberus-ykr0
---

Define CI setup for browser tests (install browsers, build assets, runtime wiring) and add mix task entrypoints where appropriate.

## Plan
- [ ] Add baseline GitHub Actions CI workflow (PR + push).
- [ ] Add non-browser test job with required setup steps.
- [ ] Add precommit/dialyzer job with explicit PLT cache.
- [ ] Verify workflow syntax and document behavior.

## Log
- [x] Confirmed there is currently no `.github/workflows` CI config in repo.
- [x] User requested CI implementation plus PLT cache verification.


- [x] Pushed workflow to main and observed first CI run (`22516203443`) fail at `setup-beam` due hex.pm mirror fetch error caused by `hexpm-mirrors: false` override.
- [x] Removed `hexpm-mirrors: false` from workflow setup-beam steps to restore default mirror behavior.
- [ ] Re-push workflow fix and verify CI passes end-to-end.
