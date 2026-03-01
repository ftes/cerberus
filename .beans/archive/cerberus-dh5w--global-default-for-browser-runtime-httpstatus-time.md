---
# cerberus-dh5w
title: Global default for browser runtime HTTP/status timeout
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:11:06Z
updated_at: 2026-02-28T08:09:46Z
---

Make browser runtime HTTP/status timeout configurable globally for slower CI and remote environments.

## Summary of Changes
Added configurable browser runtime HTTP/status timeout support via `config :cerberus, :browser, runtime_http_timeout_ms`.
Wired runtime HTTP request timeout resolution into browser runtime status/session lifecycle requests while preserving opt override precedence.
Added timeout default coverage in `test/cerberus/timeout_defaults_test.exs` and documented the new key in README timeout defaults.
