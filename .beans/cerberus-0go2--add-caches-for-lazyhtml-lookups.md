---
# cerberus-0go2
title: Add caches for LazyHTML lookups
status: todo
type: task
priority: deferred
created_at: 2026-03-03T14:44:43Z
updated_at: 2026-03-03T18:42:09Z
---

Introduce explicit caching for repeated lookup/query work on the same parsed document and operation scope.

## Detailed Findings

Current hotspot pattern in Cerberus static/live HTML resolution:
- Repeated selector queries for the same root and selector inside one operation.
- Membership checks commonly do query then Enum.any? over results for each candidate.
- This appears in node_matches_selector and field_matches_selector style paths in:
  - lib/cerberus/html/html.ex
  - lib/cerberus/phoenix/live_view_html.ex

Recent improvements already landed:
- Parse reuse was added so several APIs accept a pre-parsed LazyHTML document.
- LiveViewHTML now parses once per resolver operation for form field, submit button, trigger action forms.
- Id lookup fast paths now use query_by_id in common places.

Remaining gap this bean addresses:
- Even with parse reuse, repeated selector lookups still run many duplicate queries in one resolve pass.
- This creates avoidable NIF calls and repeated traversal for large forms and complex locators.

Proposed cache layers:
1. Per-operation root plus selector query cache in Cerberus.Html and LiveViewHTML
- Cache key: root identity plus selector text
- Value: query result set and efficient membership representation for same node checks
- Lifetime: one operation only, discard after operation completes

2. Optional reusable helper context in Cerberus resolver modules
- Thread cache through helper call chains instead of rebuilding in each helper
- Keep API surface simple by making context internal only

3. Selector membership helpers
- Replace query each time patterns with cached membership checks
- Keep behavior identical to current semantics

Expected impact:
- Small pages and simple locators: low single digit percent
- Typical form and submit locator resolution with selector filters: moderate gains
- Large DOM plus repeated selector checks: significant gains, often large multiple on the resolver hot path

Risk and constraints:
- Cache invalidation across DOM changes is mandatory
- Scope cache strictly to one snapshot and one operation
- Preserve error behavior and current matching semantics

## Suggested Work Plan
- [ ] Add operation-scoped selector cache struct and helpers.
- [ ] Migrate node and field selector matching paths to cache-backed checks.
- [ ] Add focused benchmarks around resolver hot paths.
- [ ] Add regression tests to prove semantic parity.
- [ ] Document cache lifetime and invalidation rules.
