---
# cerberus-ng1c
title: connect_params are dropped across LiveView navigation
status: completed
type: bug
priority: normal
created_at: 2026-02-27T21:48:15Z
updated_at: 2026-02-27T22:37:40Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/259

Problem:
connect_params injected for LiveView tests are present on initial visit but lost after live navigation, diverging from browser behavior where connect params persist.

Repro context from upstream issue:

```elixir
conn
|> Phoenix.LiveViewTest.put_connect_params(%{"timezone" => "Europe/Berlin"})
|> visit("/live/page_1")
# ... trigger live navigation to another LiveView ...
# expected get_connect_params/1 still includes timezone
```

Expected Cerberus parity checks:
- connect params survive live_redirect/live_navigate/live_patch flows where browser keeps the same socket context
- current_path updates do not regress when preserving connection metadata

## Todo
- [x] Add fixture that asserts connect_params before and after live navigation
- [x] Add failing conformance tests for live navigation transitions
- [x] Fix conn/session recycling path to preserve connect params where appropriate
- [x] Validate static/live/browser expectations and document caveats

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).

## Summary of Changes

- Reproduced the root cause in Cerberus: conn recycling dropped `conn.private[:live_view_connect_params]`, which can clear LiveView connect params between requests/navigations.
- Preserved LiveView connect params in `Cerberus.Driver.Conn` during `ensure_conn/1` recycle and `fork_user_conn/1` construction.
- Added fixture visibility for connect params on `/live/redirects` and `/live/counter` via `connect timezone: ...` text.
- Added a live-driver regression test asserting timezone connect params persist before and after `click_link` live navigation.
- Validation/caveat: this behavior is specific to LiveViewTest-backed flows (`:live` driver). `:browser` does not use seeded Plug conn connect params, and `:static` does not establish LiveView socket connect params.
