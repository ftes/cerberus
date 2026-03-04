---
# cerberus-nhx1
title: Document public Cerberus and Browser functions
status: completed
type: task
priority: normal
created_at: 2026-03-04T06:32:20Z
updated_at: 2026-03-04T06:38:47Z
---

Add @doc for each public function in Cerberus and Cerberus.Browser.

- [x] Inventory public functions and find missing docs
- [x] Add @doc blocks for Cerberus functions
- [x] Add @doc blocks for Cerberus.Browser functions
- [x] Include an Options section that renders nimble-options schemas where applicable
- [x] Run mix format
- [x] Run focused tests or compile checks
- [x] Run mix precommit (fails currently due unrelated Credo warnings in test/cerberus_test.exs)
- [x] Update bean summary and mark completed

## Summary of Changes
- Added @doc coverage for every public function arity in Cerberus and Cerberus.Browser.
- Added reusable NimbleOptions-rendered docs snippets and embedded them under ## Options where keyword opts schemas apply.
- Verified docs completeness with Code.fetch_docs (no missing/hidden docs in either module).
- Ran mix format.
- Ran focused checks: mix credo on edited modules and mix test test/cerberus/options_test.exs.
- mix precommit currently fails due unrelated existing Credo warnings in test/cerberus_test.exs.
