---
# cerberus-736a
title: Make EV2 Cerberus tests runnable via only cerberus and preserve originals EV2 Cerberus browser test selection away from integration so migrated Cerberus tests run via only cerberus, start Cerberus browser support from the cerbrerus tag, and move migrated Cerberus coverage out of original test files into _cerberus_test.exs copies so original PhoenixTest files remain preserved.
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:18:34Z
updated_at: 2026-03-10T16:29:12Z
---

Switch

## Progress

- Verified the correct EV2 migrated selection is `--only cerberus` without `--include integration`; `--include integration` was too broad and pulled original Playwright integration tests into the run.
- Moved migrated EV2 Cerberus coverage into new `_cerberus_test.exs` files and restored the original PhoenixTest files for the migrated set, including whole-file browser/live/controller copies and three partial-file copies (`users_live/show`, `user_controller`, `project_live/show`).
- Updated EV2 `test/test_helper.exs` so the Cerberus browser supervisor starts whenever `:cerberus` is selected, independent of `:integration`.
- Renamed migrated EV2 tags from the misspelled `:cerbrerus` to `:cerberus` and removed `:integration` tags from the Cerberus copies so they can be selected via `--only cerberus`.
- Current downstream status: running the Cerberus-only file set with `mix test --only cerberus --max-cases 14` now executes only the EV2 Cerberus copies, but still has suite-only async DB/sandbox failures in the heaviest browser-copy modules.

## Summary of Changes

- Changed EV2 Cerberus selection to run via `--only cerberus` without depending on `:integration`, including starting the Cerberus browser supervisor from the `:cerberus` include path in `test/test_helper.exs`.
- Renamed migrated EV2 tags from `:cerbrerus` to `:cerberus` and removed `:integration` tags from the Cerberus copies.
- Moved migrated EV2 Cerberus coverage into dedicated `_cerberus_test.exs` files and restored the original PhoenixTest files for the migrated set, including whole-file copies plus partial copies for `users_live/show`, `user_controller`, and `project_live/show`.
- Verified there are no remaining `:cerberus`-tagged original test files in EV2; the remaining original files importing Cerberus are unrelated native/current tests, not migrated copies.
- Verified the Cerberus-only EV2 subset is now runnable with `mix test --only cerberus --max-cases 14` and passes with `119 tests, 0 failures, 4 skipped`.
