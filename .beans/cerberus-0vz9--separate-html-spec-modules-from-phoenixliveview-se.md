---
# cerberus-0vz9
title: Separate HTML-spec modules from Phoenix/LiveView semantics in drivers
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:19:52Z
updated_at: 2026-02-28T06:30:26Z
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
- [x] Inventory driver/helper modules and classify logic as HTML vs Phoenix/LiveView.
- [x] Define target module map/namespaces for HTML and Phoenix/LiveView layers.
- [x] Move/refactor shared HTML semantics into HTML modules with tests.
- [x] Move/refactor Phoenix/LiveView semantics into dedicated modules with tests.
- [x] Add spec links for each HTML behavior area.
- [x] Add/adjust conformance coverage to validate separation and behavior parity.
- [x] Update architecture docs to describe layering and boundaries.

## Acceptance Criteria
- [x] HTML semantics are implemented in HTML-focused modules without Phoenix/LiveView dependencies.
- [x] Phoenix/LiveView modules contain only framework semantics and call into HTML modules as needed.
- [x] Tests clearly distinguish HTML semantic tests from Phoenix/LiveView semantic tests.
- [x] Architecture/docs include explicit module boundaries and reference links.

## Summary of Changes
- Created `Cerberus.Driver.LiveViewHtml` and moved LiveView-specific HTML semantics into it (`phx-click` actionable button resolution, `phx-change`/`phx-submit` metadata, `phx-trigger-action` form detection).
- Simplified `Cerberus.Driver.Html` to HTML-platform semantics only and removed LiveView-specific behavior/fields from its API.
- Updated `Cerberus.Driver.Live` to consume `LiveViewHtml` for framework semantics while static paths continue using `Driver.Html`.
- Split tests by layer (`Driver.HtmlTest` for HTML behavior and new `Driver.LiveViewHtmlTest` for LiveView behavior) and validated parity with full suite + `mix precommit`.
- Added explicit module-boundary docs in README, `doc/readme.md`, and ADR-0001 plus WHATWG spec links in `Driver.Html` moduledoc.
