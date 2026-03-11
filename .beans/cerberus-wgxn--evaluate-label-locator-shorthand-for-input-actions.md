---
# cerberus-wgxn
title: Evaluate label-locator shorthand for input actions
status: completed
type: task
priority: normal
created_at: 2026-03-11T12:34:41Z
updated_at: 2026-03-11T12:36:43Z
---

Assess whether input action functions should implicitly treat a text locator in arg 2 as a label locator, similar to select/3 treating arg 3 text locators as option locators.

- [x] inspect current action API semantics and normalization paths
- [x] compare with legacy adapter behavior and documented locator guidance
- [x] recommend whether to add arg-2 text->label coercion and explain tradeoffs

## Summary of Changes

Reviewed the public action APIs, form-locator normalization, HTML/browser form-field resolution, legacy adapters, and existing tests. Confirmed that form actions already accept `text(...)` in arg 2 and match it against field labels in form-field context, while `select/3` arg 3 remains a stricter option-text-only slot. Recommendation: keep supporting `text(...)` for form actions, but avoid adding a separate hard coercion step that rewrites arg 2 into a label locator.
