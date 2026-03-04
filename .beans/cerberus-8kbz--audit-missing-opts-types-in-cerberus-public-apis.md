---
# cerberus-8kbz
title: Audit missing opts types in Cerberus public APIs
status: completed
type: task
priority: normal
created_at: 2026-03-04T19:32:45Z
updated_at: 2026-03-04T19:33:46Z
---

## Goal
Identify public functions in Cerberus and Cerberus.Browser that still use generic opts typing and list missing specific option types from Cerberus.Options.

## Tasks
- [x] Inventory public functions and their current @spec opts types in Cerberus
- [x] Inventory public functions and their current @spec opts types in Cerberus.Browser
- [x] Compare against available Cerberus.Options opt types and schemas
- [x] Produce concrete missing list and recommended type aliases

## Summary of Changes
- Audited Cerberus and Cerberus.Browser public specs and mapped generic keyword opts usage.
- Identified that locator-constructor opts are still untyped keywords in Cerberus and Locator modules.
- Identified minor remaining generic keyword usage in Browser screenshot wrapper spec and generic keyword usage for visit and reload_page in Cerberus.
- Produced concrete list of missing option type aliases needed for stronger typing.
