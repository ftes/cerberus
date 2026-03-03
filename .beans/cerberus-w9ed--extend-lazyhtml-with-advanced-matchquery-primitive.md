---
# cerberus-w9ed
title: Extend LazyHTML with advanced match/query primitives
status: todo
type: task
priority: normal
created_at: 2026-03-03T14:44:43Z
updated_at: 2026-03-03T14:45:25Z
---

Add lower-level NIF-backed primitives to reduce selector parse/setup overhead and avoid repeated query plus filter orchestration in Elixir.

## Detailed Findings

Native LazyHTML NIF currently reparses selectors on each query call.
Evidence in deps/lazy_html/c_src/lazy_html.cpp:
- query creates css parser, parses selector, creates selectors engine, executes find, then destroys all objects.
  - around lines 670 to 730
- filter does similar setup and teardown per call.
  - around lines 732 to 780
- query_by_id currently walks nodes and descendants each call, deduplicating with a local set.
  - around lines 799 to 839

Implication:
- Cross-call selector compile reuse is not present in current NIF implementation.
- Cerberus calling query repeatedly for same selector on same doc pays parse and setup overhead every time.

Why this bean exists separately from Cerberus caching:
- Cerberus-side cache can remove many duplicate calls but cannot reduce per-call selector compile overhead when a call is still needed.
- New native primitives can collapse whole Elixir orchestration patterns into fewer NIF calls.

Proposed primitive extensions in LazyHTML:
1. Compiled selector handle API
- compile_selector(selector) returns an opaque selector resource
- query_compiled(doc_or_nodes, compiled_selector)
- filter_compiled(nodes, compiled_selector)

2. Direct match primitive
- matches(nodes, selector_or_compiled)
- Returns booleans per node or filtered nodes
- Replaces many query then membership patterns in Elixir

3. Bulk helpers for common resolver needs
- query_many with selector list in one native call
- optional query plus projection to fetch minimal metadata in one pass

4. Optional indexed lookups
- doc-scoped id index for repeated id lookup heavy workloads
- possibly generic attribute index if profiling justifies it

Expected impact:
- Lower overhead per query due to selector parse and setup reuse
- Fewer NIF crossings when orchestration can be done natively
- Better scaling on complex locator workloads

Risk and constraints:
- API design must keep memory ownership and resource lifetime safe
- Need clear invalidation semantics for compiled selector resources relative to docs
- Keep backward compatible surface for existing LazyHTML users

## Suggested Work Plan
- [ ] Add baseline benchmarks in lazy_html for repeated query and match workloads.
- [ ] Implement compiled selector resource and query_compiled path.
- [ ] Add matches primitive and tests for selector semantics.
- [ ] Expose Elixir API and docs for new primitives.
- [ ] Integrate in Cerberus behind focused adapters and verify parity.
