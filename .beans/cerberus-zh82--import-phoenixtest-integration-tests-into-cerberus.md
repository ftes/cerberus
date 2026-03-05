---
# cerberus-zh82
title: Import PhoenixTest integration tests into Cerberus
status: todo
type: feature
created_at: 2026-03-05T06:35:53Z
updated_at: 2026-03-05T06:35:53Z
---

## Goal
Add the PhoenixTest integration coverage into Cerberus, keeping upstream test structure as intact as possible while migrating call syntax to Cerberus APIs.

## Scope
In scope integration files from ../phoenix_test/test/phoenix_test:
- assertions_test.exs
- static_test.exs
- live_test.exs
- conn_handler_test.exs (integration visit scenarios)

Out of scope from this bean (unit and internals):
- query_test.exs
- session_helpers_test.exs
- element_test.exs
- locators_test.exs
- form_data_test.exs
- form_payload_test.exs
- html_test.exs
- data_attribute_form_test.exs
- active_form_test.exs
- utils_test.exs
- live_view_timeout_test.exs
- live_view_bindings_test.exs
- live_view_watcher_test.exs
- credo/no_open_browser_test.exs
- element/*_test.exs

## Phased Plan
- [ ] Phase 1: copy server fixture modules from ../phoenix_test/test/support/web_app into test/support/fixtures with minimal edits and merge into existing fixture app
- [ ] Phase 2: add phoenix_test route namespace in fixture router so copied static and live routes run under /phoenix_test/*
- [ ] Phase 3: port assertions_test.exs and static_test.exs mostly verbatim, rewriting only to Cerberus syntax
- [ ] Phase 4: port live_test.exs mostly verbatim, rewriting only to Cerberus syntax
- [ ] Phase 5: port integration scenarios from conn_handler_test.exs and skip pure helper unit sections
- [ ] Phase 6: run mix format and targeted tests after each file batch using source .envrc and random PORT=4xxx
- [ ] Phase 7: run mix do format + precommit + test + test.slow before final commit for this bean

## Notes
- Keep copied controller and liveview fixture behavior aligned with upstream unless it conflicts with existing Cerberus fixtures.
- Prefer direct manual syntax migration over igniter for this port.
