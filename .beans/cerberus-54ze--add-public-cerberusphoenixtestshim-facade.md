---
# cerberus-54ze
title: Add public Cerberus.PhoenixTestShim facade
status: completed
type: feature
priority: normal
created_at: 2026-03-05T08:47:13Z
updated_at: 2026-03-05T08:55:02Z
---

Create a public PhoenixTest compatibility facade for Cerberus that covers most PhoenixTest action/assert APIs with simple mapping semantics inspired by test support legacy module.

## Todo
- [x] Add public shim module inspired by legacy facade
- [x] Keep shim separate from test support legacy implementation
- [x] Cover common PhoenixTest style helper shapes with simple mappings
- [x] Add focused shim tests
- [x] Update README migration docs with shim guidance
- [x] Run format and validation tests

## Summary of Changes
- Added a new public Cerberus PhoenixTest shim module with use support and compatibility helper APIs.
- Added nested Assertions and TestHelpers shim modules.
- Covered common navigation assertion and action helpers plus practical browser helper passthroughs.
- Kept shim implementation separate from test support legacy module.
- Added shim compatibility tests and README documentation.
- Validation: shim test file passed, full mix test passed, and mix test only slow passed. mix precommit is blocked by unrelated existing Credo suggestions outside this change.
