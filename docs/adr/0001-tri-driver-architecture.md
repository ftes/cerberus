# ADR 0001: Tri-Driver Architecture with Shared Semantics

Status: Accepted
Date: 2026-02-27
Owner bean: cerberus-sfku

## Context
Cerberus must support static, LiveView, and browser execution with one user-facing API while minimizing semantic drift.

## Decision
Adopt a tri-driver architecture with a strict shared semantic core:
- Driver adapters execute side effects and gather observations.
- Locator normalization and text assertion semantics are centralized.
- Public API remains driver-agnostic and session-first.

## Consequences
Positive:
- One semantic definition for assertions.
- Cleaner conformance testing.
- Easier browser-oracle comparisons.

Negative:
- Extra translation layer from public API to driver callbacks.
- Requires discipline to avoid semantic logic leakage into drivers.

## References
- milestone: cerberus-efry
- epic: cerberus-sfku
