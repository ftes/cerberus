# ADR 0004: Browser Runtime Supervision Topology

Status: Accepted
Date: 2026-02-27
Owner bean: cerberus-y6gj
Related beans: cerberus-sfku, cerberus-k4m0, cerberus-g0jq

## Context
The previous browser adapter started one runtime + one BiDi transport per test session.
That model made browser startup expensive and did not match the agreed architecture:
- single shared browser process,
- single shared BiDi connection,
- isolated `userContext` per test,
- dedicated `browsingContext` workers for tab/window scope.

## Decision
Adopt the following supervision tree and restart strategy:

```text
Cerberus.Driver.Browser.Supervisor (rest_for_one)
├─ Cerberus.Driver.Browser.Runtime
├─ Cerberus.Driver.Browser.BiDiSupervisor (one_for_all)
│  ├─ Cerberus.Driver.Browser.BiDiSocket
│  └─ Cerberus.Driver.Browser.BiDi
└─ Cerberus.Driver.Browser.UserContextSupervisor (DynamicSupervisor)
   └─ Cerberus.Driver.Browser.UserContextProcess (one per test, temporary)
      └─ Cerberus.Driver.Browser.BrowsingContextSupervisor
         └─ Cerberus.Driver.Browser.BrowsingContextProcess (one per browsingContext, temporary)
```

## Restart Behavior
- Top-level `rest_for_one` ensures runtime failures restart transport and all test-scoped workers.
- `BiDiSupervisor` uses `one_for_all` so socket/connection recover as a pair.
- `UserContextProcess` and `BrowsingContextProcess` are `temporary` so test failures do not auto-heal silently.
- When a test owner exits, its `UserContextProcess` stops and associated `browsingContext` workers are torn down.

## Consequences
Positive:
- Browser and BiDi setup cost is amortized across tests.
- Test isolation remains explicit through per-test `userContext`.
- Event handling can evolve at `browsingContext` granularity without changing global transport.

Negative:
- Shared transport introduces a central failure domain.
- Per-test runtime option overrides are constrained relative to per-session runtime startup.
