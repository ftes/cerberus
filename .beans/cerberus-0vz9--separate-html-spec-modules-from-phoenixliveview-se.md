---
# cerberus-0vz9
title: Separate HTML-spec modules from Phoenix/LiveView semantics in drivers
status: in-progress
type: task
created_at: 2026-02-27T22:19:52Z
updated_at: 2026-02-27T22:19:52Z
parent: cerberus-sfku
---

## Objective
Create a strict architectural separation between generic HTML behavior and Phoenix/LiveView-specific behavior in driver code.

## Problem
Current driver-related modules mix HTML semantics and Phoenix/LiveView semantics, making behavior harder to reason about and test.

## Proposed Direction
- Introduce HTML-centric modules that map closely to browser/HTML standards concepts.
- Keep framework semantics in dedicated Phoenix/LiveView modules.
- Ensure Phoenix/LiveView layers compose over HTML modules instead of embedding HTML rules directly.

## Design Constraints
- HTML modules should model platform semantics first (forms, inputs, labels, buttons, events, attributes, ownership, submission behavior).
- Add inline links in moduledocs/docs to relevant specs (WHATWG HTML + related platform docs) where behavior is implemented.
- Phoenix/LiveView modules should only model framework behavior (phx-change, phx-submit, live navigation, trigger-action, watcher/lifecycle semantics, etc.).

## Work Breakdown
- [ ] Inventory driver/helper modules and classify logic as HTML vs Phoenix/LiveView.
- [ ] Define target module map/namespaces for HTML and Phoenix/LiveView layers.
- [ ] Move/refactor shared HTML semantics into HTML modules with tests.
- [ ] Move/refactor Phoenix/LiveView semantics into dedicated modules with tests.
- [ ] Add spec links for each HTML behavior area.
- [ ] Add/adjust conformance coverage to validate separation and behavior parity.
- [ ] Update architecture docs to describe layering and boundaries.

## Acceptance Criteria
- [ ] HTML semantics are implemented in HTML-focused modules without Phoenix/LiveView dependencies.
- [ ] Phoenix/LiveView modules contain only framework semantics and call into HTML modules as needed.
- [ ] Tests clearly distinguish HTML semantic tests from Phoenix/LiveView semantic tests.
- [ ] Architecture/docs include explicit module boundaries and reference links.
