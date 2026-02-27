---
# cerberus-mz94
title: fill_in label matching fails with nested label nodes
status: completed
type: bug
priority: normal
created_at: 2026-02-27T21:47:48Z
updated_at: 2026-02-27T22:41:33Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/287

Problem:
fill_in fails when label text includes nested elements (e.g. required marker <span>*</span>), so exact label resolution diverges from user-visible label text.

Repro snippet from upstream:

```html
<label>
  Some label<span class="required">*</span>
  <input ... />
</label>
```

```elixir
|> fill_in("Some label *", with: "...")
```

Expected Cerberus parity checks:
- label text extraction should include nested inline text content consistently.
- fill_in exact/non-exact matching should be deterministic across static/live/browser.

## Todo
- [x] Add fixture + failing tests for nested label text content
- [x] Define/normalize label text extraction semantics (whitespace + inline nodes)
- [x] Implement fix in shared label lookup path
- [x] Verify cross-driver conformance against browser behavior

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).

## Summary of Changes

- Added nested-label fixtures where controls are wrapped by `<label>` and label text includes inline nested nodes (`<span>*</span>`).
- Added conformance coverage for nested-label `fill_in` on both static+browser and live+browser paths.
- Added a focused `Cerberus.Driver.Html` unit test proving wrapped nested label text resolves to a matchable label string.
- Fixed browser driver form-field label resolution to support both `label[for]` and wrapped controls via `closest("label")` fallback.
- Verified the scenario across targeted conformance suites and driver-level tests.
