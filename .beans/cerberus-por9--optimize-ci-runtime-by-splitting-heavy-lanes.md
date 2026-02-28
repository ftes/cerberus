---
# cerberus-por9
title: Optimize CI runtime by splitting heavy lanes
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:30:55Z
updated_at: 2026-02-28T19:33:26Z
parent: cerberus-it5x
---

Run-level optimization for GitHub Actions CI based on job 65261422979.

## Todo
- [x] Confirm bottlenecks from the linked run and logs
- [x] Split workflow lanes to reduce wasted work on failures
- [x] Keep required checks equivalent in coverage
- [x] Validate workflow syntax and run local fast checks
- [x] Add summary of changes and measured impact expectations

## Summary of Changes

- Analyzed run `22527384777` / job `65261422979` step timings and identified the heaviest sequential segments: `Run precommit` (~140s) and `Run migration verification tests` (~76s), with browser lane after those in the same job.
- Split CI into three parallel jobs: `Quality`, `Migration Verification`, and `Browser Conformance`.
- Added a final aggregate `CI` job that depends on all three lanes and fails if any lane fails, preserving a single top-level gate.
- Kept test scope equivalent: precommit checks, migration verification, browser conformance, and remote webdriver lane all still execute.
- Validation performed: `mix format`, `mix precommit`, YAML parse of `.github/workflows/ci.yml`.
