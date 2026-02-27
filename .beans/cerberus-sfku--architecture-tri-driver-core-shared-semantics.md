---
# cerberus-sfku
title: 'Architecture: Tri-Driver Core + Shared Semantics'
status: todo
type: epic
priority: normal
created_at: 2026-02-27T07:40:25Z
updated_at: 2026-02-27T07:40:38Z
parent: cerberus-efry
---

## Objective
Build a minimal but extensible architecture where all drivers share one semantic layer.

## Proposed Modules
```elixir
Cerberus
Cerberus.Session
Cerberus.Driver           # behaviour
Cerberus.Driver.Static
Cerberus.Driver.Live
Cerberus.Driver.Browser
Cerberus.Locator          # parse + normalize to AST
Cerberus.Query            # text matching semantics
Cerberus.Assertions       # assert/refute orchestration
Cerberus.Runtime          # one-shot now; waiting engine later
Cerberus.Errors
```

## Driver Behaviour (Slice 1)
```elixir
@callback visit(session, path, opts) :: session
@callback assert_has(session, locator_ast, opts) :: {:ok, session} | {:error, term}
@callback refute_has(session, locator_ast, opts) :: {:ok, session} | {:error, term}
@callback click(session, locator_ast, opts) :: {:ok, session} | {:error, term}
@callback render_debug(session) :: map
```

## Session Shape
```elixir
%Cerberus.Session{
  driver: :static | :live | :browser,
  driver_state: term,
  current_path: String.t() | nil,
  last_result: map | nil,
  meta: map
}
```

## Shared Semantics
Text matching must be implemented once and reused by all drivers.
Normalization contract:
- whitespace collapse on by default (`normalize_ws: true`)
- exact false by default (`exact: false`)
- visibility default true (`visible: true`)

## Slice 1 Implementation Rules
- One-shot only (no retries/backoff/wait loops yet).
- Driver returns raw match data; `Cerberus.Assertions` formats human-readable errors.
- Browser driver allowed to be minimal and slow in slice 1 if semantics are correct.

## Work Breakdown
- [ ] Define `Cerberus.Session` and constructors for static/live/browser.
- [ ] Define `Cerberus.Driver` behaviour and wire adapters.
- [ ] Implement `Cerberus.Locator.normalize/1` for text-only locators.
- [ ] Implement shared `Cerberus.Query.match_text?/3` semantics.
- [ ] Implement `Cerberus.Assertions.assert_has/refute_has` around driver callbacks.
- [ ] Add explicit error structs and consistent failure messages.

## Acceptance Criteria
- [ ] Same locator/options produce same pass/fail result across all drivers on identical fixture content.
- [ ] Failure output includes driver, locator, options, and observed values.
- [ ] No driver duplicates text normalization logic.
