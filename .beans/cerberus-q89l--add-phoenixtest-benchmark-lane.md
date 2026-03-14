---
# cerberus-q89l
title: Add PhoenixTest benchmark lane
status: completed
type: feature
priority: normal
created_at: 2026-03-13T17:35:01Z
updated_at: 2026-03-14T13:59:19Z
---

- [x] Review existing benchmark harness and performance fixture reuse
- [ ] Add a PhoenixTest benchmark runner that works with ExUnit sandbox-owned conns
- [x] Cover the new lane with targeted tests and matrix integration
- [x] Update benchmark docs and summarize results

## Summary of Changes

- Added a real PhoenixTest benchmark lane that runs inside ExUnit with sandbox-owned conns against the existing performance LiveView.
- Wired the PhoenixTest lane into the benchmark matrix and documented it in the browser benchmark guide.
- Added targeted PhoenixTest benchmark support tests, migrated the useful legacy value assertion into vanilla Cerberus coverage, and removed the unused PhoenixTest compatibility shim files.
- Verified with focused PhoenixTest benchmark tests, a one-row matrix smoke run, and a full `mix test` pass (632 tests, 0 failures). Credo still reports one pre-existing complexity issue in `lib/cerberus/driver/live.ex` outside this slice.

## Final Notes

- Kept the PhoenixTest benchmark lane in the matrix and docs after follow-up benchmark work extended the harness.
- Moved PhoenixTest benchmark support modules under bench/ so the lane stays opt-in and does not bloat the normal test suite or dialyzer path.
- Verified the final tree with MIX_ENV=test mix do format + precommit + test (630 tests, 0 failures).
