---
# cerberus-4vb3
title: Design true multi-browser runtime in one test invocation
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:55:21Z
updated_at: 2026-02-28T19:56:40Z
---

## Goal
Plan how Cerberus can run chrome and firefox truly in one test invocation (not sequential invocations), including runtime/supervisor/API/test implications.

## Todo
- [x] Analyze current runtime single-browser constraints
- [x] Propose architecture for per-browser runtime sessions in one run
- [x] Define migration strategy and validation plan
- [x] Summarize recommended implementation phases

## Summary of Changes
- Identified hard blocker: browser runtime and BiDi transport are currently global singletons and explicitly reject browser switching in one invocation.
- Proposed target architecture: per-browser lane supervisors (chrome/firefox), each with its own Runtime process, BiDi socket/process, and user-context supervisor.
- Recommended introducing a RuntimeManager that resolves lane by browser_name and lazily starts missing lanes.
- Recommended propagating lane/browser identity through Browser session startup into UserContextProcess and BrowsingContextProcess so BiDi calls are lane-scoped instead of global.
- Recommended extending remote config to support per-browser webdriver URLs (for example webdriver_urls: [chrome: ..., firefox: ...]).
- Recommended changing mix test.websocket multi-browser mode from sequential full-suite runs to one invocation with both remote lanes available.
- Defined phased rollout with compatibility shim and focused regression tests.

## Recommended Phases
1) Add runtime lane manager + lane-scoped process naming without changing public API.
2) Move UserContext/BrowsingContext to lane-scoped BiDi and runtime access.
3) Enable explicit :chrome/:firefox in one run and make harness driver tags map to real browser lanes.
4) Add per-browser remote URL config and run websocket chrome+firefox in a single mix test invocation.
5) Tighten CI coverage and remove transitional sequential mode once stable.
