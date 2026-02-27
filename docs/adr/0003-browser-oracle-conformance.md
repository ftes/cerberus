# ADR 0003: Browser as Oracle for Conformance Reporting

Status: Accepted
Date: 2026-02-27
Owner bean: cerberus-syh3

## Context
Static and Live drivers can diverge from true browser behavior in visibility, text normalization, and navigation timing.

## Decision
For designated conformance suites, treat browser results as the oracle and compare static/live outcomes to browser outcomes.

## Scope
- Slice 1: one-shot assertions and simple click flows.
- Future slices: waiting/event semantics and richer locator support.

## Report Requirements
Each mismatch report must include:
- scenario id
- operation
- locator + options
- static/live observed values
- browser observed values
- mismatch category label

## Example Category Labels
- `visibility`
- `normalize_ws`
- `exact_match`
- `count_or_order`
- `navigation_state`

## Consequences
Positive:
- Faster detection of semantic drift.
- Better confidence when expanding API/locators.

Negative:
- Requires reliable browser environments in CI.
- Browser flakiness can affect confidence if not controlled.

## References
- milestone: cerberus-efry
- epic: cerberus-syh3
