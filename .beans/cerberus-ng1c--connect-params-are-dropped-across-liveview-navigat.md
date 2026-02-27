---
# cerberus-ng1c
title: connect_params are dropped across LiveView navigation
status: in-progress
type: bug
priority: normal
created_at: 2026-02-27T21:48:15Z
updated_at: 2026-02-27T22:35:41Z
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
- [ ] Add fixture that asserts connect_params before and after live navigation
- [ ] Add failing conformance tests for live navigation transitions
- [ ] Fix conn/session recycling path to preserve connect params where appropriate
- [ ] Validate static/live/browser expectations and document caveats

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).
