---
# cerberus-ayng
title: Add docs warnings-as-errors to precommit
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:25:58Z
updated_at: 2026-02-27T22:28:31Z
---

## Objective
Ensure mix precommit runs docs generation and fails on docs warnings.

## Done When
- [x] mix precommit includes docs generation.
- [x] Docs generation is configured to fail on warnings.
- [x] Dependency/env setup supports running docs in precommit env.
- [x] Formatting is clean after changes.

## Summary of Changes
- Updated precommit alias to include docs generation with strict warnings handling: docs --warnings-as-errors --formatter html.
- Expanded ex_doc dependency scope to dev and test so docs can run under the existing precommit test environment.
- Ran mix format and then mix precommit to verify enforcement behavior.
- Confirmed precommit now fails on existing docs warnings, forcing warning cleanup before precommit can pass.

## Follow-up (2026-02-27)
- [x] Eliminate docs warnings from hidden Cerberus.Options type references.
- [x] Verify mix docs --warnings-as-errors --formatter html passes.
- [x] Verify mix precommit passes with strict docs step.

## Summary of Changes (Follow-up)
- Made Cerberus.Options visible in generated docs by replacing moduledoc false with a real moduledoc.
- Re-ran strict docs generation: mix docs --warnings-as-errors --formatter html (passes).
- Re-ran mix precommit and confirmed the docs step now passes under warnings-as-errors.
