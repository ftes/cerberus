---
# cerberus-6hda
title: 'CI browser pipeline: install, assets, orchestration, and mix tasks'
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T07:07:19Z
updated_at: 2026-02-28T07:31:54Z
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


- [x] Second CI run (`22516217035`) still failed in `setup-beam` with rebar mirror resolution (`Could not mix rebar from any hex.pm mirror`).
- [x] Added fallback hex.pm mirror (`https://cdn.jsdelivr.net/hex`) in workflow `setup-beam` configuration for both jobs.
- [ ] Push mirror fallback change and verify CI passes.


- [x] Reworked CI to a standard setup-beam pattern: use `version-file: .tool-versions` with strict resolution, disable action-managed hex/rebar install, and install via `mix local.hex --force` + `mix local.rebar --force`.
- [ ] Push this normalization and verify CI passes.


- [x] CI failure root cause identified from run logs: `mix` evaluated `config/test.exs` before browser env setup, causing `System.fetch_env!("CHROME")` failure.
- [x] Reordered workflow so browser runtime env is prepared before any `mix` command (including `mix local.hex`/`mix deps.get`).
- [ ] Push ordering fix and verify CI passes.
