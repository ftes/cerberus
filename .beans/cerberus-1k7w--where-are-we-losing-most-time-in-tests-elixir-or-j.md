---
# cerberus-1k7w
title: 'Where are we losing most time in tests: Elixir or JavaScript?'
status: in-progress
type: task
priority: normal
created_at: 2026-03-03T12:51:28Z
updated_at: 2026-03-03T12:55:55Z
---

## Goal
Identify whether test runtime is primarily spent in Elixir or JavaScript execution paths.

## Scope
Phase 1: Instrument only Elixir, including explicit timing for any Elixir-side wait spent waiting on JS/browser responses.
Phase 2 (conditional): If JS appears to be a hotspot from Phase 1 results, add JavaScript-side instrumentation to break down time inside browser-executed code.

## Todo
- [ ] Add Elixir-side timing instrumentation around key test-driver operations
- [ ] Add dedicated timing buckets for Elixir wait time spent waiting for JS/browser completion
- [ ] Run representative test subsets and collect aggregated timing data
- [ ] Decide whether JS is a hotspot from collected data
- [ ] If JS is a hotspot, add JS-side instrumentation and rerun measurement
- [ ] Summarize findings with Elixir vs JS time split and next actions
