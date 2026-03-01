---
# cerberus-m2x8
title: Remove browser matrix env and make browser drivers explicit
status: completed
type: task
priority: normal
created_at: 2026-02-28T14:03:04Z
updated_at: 2026-02-28T14:32:38Z
---

## Goal
Switch CI from browser matrix to a single explicit browser job, remove global CERBERUS_BROWSER_MATRIX switching, and make repository tests explicitly declare chrome/firefox drivers.

## Todo
- [x] Collapse CI into a single non-matrix job with explicit chrome+firefox runs
- [x] Remove CERBERUS_BROWSER_MATRIX config path from test config/harness
- [x] Keep default :browser lanes and add explicit chrome/firefox showcase tagging
- [x] Remove CERBERUS_BROWSER_MATRIX from public docs
- [x] Run mix format and mix precommit
- [x] Summarize changes

## Summary of Changes
- Collapsed CI from three jobs (smoke/precommit/browser matrix) into one `ci` job with sequential steps.
- Removed browser matrix strategy and all `CERBERUS_BROWSER_MATRIX` usage from workflow/runtime setup.
- CI now provisions both runtimes explicitly in one step via `bin/check_chrome_bidi_ready.sh --install` and `bin/check_firefox_bidi_ready.sh --install`, then exports all four binaries (`CHROME`, `CHROMEDRIVER`, `FIREFOX`, `GECKODRIVER`).
- Removed test-config browser matrix env parsing from `config/test.exs`.
- Simplified harness driver selection to use explicit `context[:drivers]` entries only (no `:browser` expansion), and ensured browser session-option merges apply to `:browser`, `:chrome`, and `:firefox`.
- Updated conformance tests from `drivers: [..., :browser]` to explicit `drivers: [..., :chrome, :firefox]` across core suites.
- Converted direct browser-core tests to explicit per-browser runs (looped tests in browser extensions, browser multi-session conformance, and docs browser snippet tests).
- Removed `CERBERUS_BROWSER_MATRIX` references from public docs (`README.md`, `docs/getting-started.md`, `docs/browser-support-policy.md`).
- Validation:
  - `mix format` passed.
  - `mix precommit` passed.
  - `mix test test/cerberus/harness_test.exs` passed with explicit browser env exported.
  - `mix test test/core/documentation_examples_test.exs --only browser` passed with explicit browser env exported.

## Summary Update
- Kept existing conformance modules on `drivers: [:browser]` so Chrome remains the default baseline lane.
- Added a dedicated showcase module at `test/core/browser_tag_showcase_test.exs` demonstrating:
  - module-level tags (`@moduletag drivers: [:browser]`),
  - describe-level override (`@describetag drivers: [:firefox]`),
  - test-level override (`@tag drivers: [:chrome, :firefox]`).
- Updated docs to describe targeted explicit browser tags instead of global matrix env switching.
- Additional validation after this scope adjustment:
  - `mix test test/core/browser_tag_showcase_test.exs` passed with explicit browser env exported.
  - `mix test test/cerberus/harness_test.exs` passed with explicit browser env exported.
