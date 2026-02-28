---
# cerberus-6hda
title: 'CI browser pipeline: install, assets, orchestration, and mix tasks'
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T07:07:19Z
updated_at: 2026-02-28T07:22:11Z
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
