---
# cerberus-xn3m
title: Improve failure diagnostics with candidate hints
status: completed
type: task
priority: normal
created_at: 2026-03-04T06:30:17Z
updated_at: 2026-03-04T06:36:43Z
---

Add PhoenixTest-style candidate diagnostics for assertion/action failures.

- [x] Improve assert_has/refute_has failure output with useful candidate values
- [x] Improve click/fill_in/submit/upload failure output with candidate hints where available
- [x] Add/adjust tests that assert richer messages (including browser parity where applicable)
- [x] Run format and relevant tests

## Summary of Changes

- Extended shared assertion error formatting to append `possible candidates` when observed payload includes candidate values (or text assertion candidates on mismatch).
- Added browser action diagnostics payload support by returning `candidateValues`/`candidateCount` from browser action resolver JS and surfacing them in browser observed data.
- Added candidate collection for static/live action failures (`click`, `fill_in`, `submit`, `upload`) so missing-target errors now include useful alternatives.
- Added cross-driver parity tests covering richer failure diagnostics for `assert_has`, `click_link`, `fill_in`, and `submit`.
- Ran `mix format` and targeted tests: `cross_driver_text_test.exs`, `form_actions_test.exs`, and `api_examples_test.exs`.
