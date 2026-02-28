# ADR 0002: Session-First API and Locator-as-First-Arg

Status: Accepted
Date: 2026-02-27
Owner bean: cerberus-ktki

## Context
A prior style using explicit `locate(...)` in the pipe risks confusion about the piped value type (session vs located node).

## Decision
All public operations take `session` first and return `session`.
Locator is passed as the first operation argument after session.
No public located-element pipeline type in v0.

## API
```elixir
visit(session, path_or_url, opts \\ [])
click(session, locator, opts \\ [])
assert_has(session, locator, opts \\ [])
refute_has(session, locator, opts \\ [])
```

## Example
```elixir
session
|> visit("/live/counter")
|> click([text: "Increment"])
|> assert_has([text: "Count: 1", exact: true])
```

## Consequences
Positive:
- Pipe is unambiguous.
- Easier type contracts and docs.

Negative:
- Options and locator can be harder to distinguish if locator is keyword-heavy.
- Requires clear validation/error messages for invalid locator forms.

## References
- milestone: cerberus-efry
- epic: cerberus-ktki
