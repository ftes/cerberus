---
# cerberus-dcoz
title: Igniter-based migration task for PhoenixTest consumers
status: todo
type: task
priority: normal
created_at: 2026-02-27T12:26:33Z
updated_at: 2026-02-27T12:26:41Z
---

Create an Igniter-powered migration path so consumers can migrate existing PhoenixTest test modules to Cerberus with minimal manual edits.

## Proposed Scope
- [ ] Add an Igniter task (e.g. `mix igniter.cerberus.migrate_phoenix_test`) that scans test files.
- [ ] Rewrite core module references from `PhoenixTest` to `Cerberus` where safe.
- [ ] Migrate common API calls to Cerberus equivalents and flag unsupported cases.
- [ ] Add dry-run + diff output so users can preview changes.
- [ ] Add integration tests covering representative PhoenixTest fixtures.
- [ ] Document migration usage and caveats in guides/README.
