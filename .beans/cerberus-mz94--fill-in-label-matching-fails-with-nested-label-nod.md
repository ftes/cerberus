---
# cerberus-mz94
title: fill_in label matching fails with nested label nodes
status: todo
type: bug
created_at: 2026-02-27T21:47:48Z
updated_at: 2026-02-27T21:47:48Z
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
- [ ] Add fixture + failing tests for nested label text content
- [ ] Define/normalize label text extraction semantics (whitespace + inline nodes)
- [ ] Implement fix in shared label lookup path
- [ ] Verify cross-driver conformance against browser behavior
