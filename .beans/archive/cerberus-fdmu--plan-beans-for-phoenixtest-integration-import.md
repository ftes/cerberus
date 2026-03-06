---
# cerberus-fdmu
title: Plan beans for PhoenixTest integration import
status: completed
type: task
priority: normal
created_at: 2026-03-05T06:35:10Z
updated_at: 2026-03-05T06:36:23Z
---

## Goal
Create actionable beans for importing integration tests from phoenix_test and phoenix_test_playwright into Cerberus.

## Checklist
- [x] Review current beans to avoid collisions with in-progress work
- [x] Inventory upstream integration tests and server fixture files
- [x] Create migration bean for PhoenixTest integration tests with phased file batches
- [x] Create migration bean for PhoenixTestPlaywright integration tests with phased file batches
- [x] Link sequencing to minimize router and fixture edit conflicts

## Summary of Changes
Created two feature beans with phased, file-level migration plans for upstream integration tests and server fixture copying. The PhoenixTestPlaywright bean is marked blocked by the PhoenixTest bean to avoid concurrent edits to shared fixture and router files.
