---
# cerberus-beaw
title: Research removing public mode selector (:auto/:static/:live/:browser)
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:38:41Z
updated_at: 2026-02-27T22:42:35Z
---

Investigate whether Cerberus can drop public mode selector from API.

Scope:
- Audit current API and test usage of :auto/:static/:live/:browser
- Verify if practical choice is only non-browser vs browser
- Compare with PhoenixTest/PhoenixTest.Playwright API shape
- Propose migration path if selector should be removed

## Todo
- [x] Inventory current mode usage in public API, docs, and tests
- [x] Check PhoenixTest/PhoenixTest.Playwright behavior and API
- [x] Write recommendation with tradeoffs
- [x] Capture follow-up implementation tasks (if any)

## Findings

- Public API currently exposes four driver atoms via session/2: :auto, :static, :live, :browser (lib/cerberus.ex).
- :auto and :browser are the harness default for conformance runs (test/support/harness.ex, @default_drivers [:auto, :browser]).
- Internal conformance coverage relies heavily on explicit :static/:live targeting:
  - driver tag combinations in test/core: 13x [:static, :browser], 21x [:live, :browser], 9x [:live], 2x [:static, :live], 1x [:static, :live, :browser], 1x [:browser].
  - several tests assert live-only or static/live-only edge semantics directly (for example test/core/live_trigger_action_conformance_test.exs and test/core/form_button_ownership_test.exs).
- README currently documents all four as public modes and positions :static/:live as focused conformance modes.

## PhoenixTest + PhoenixTest.Playwright Reference

- PhoenixTest has no public mode selector like :static/:live; it starts with visit(conn, path) and auto-detects page type from the resulting conn/view shape (ConnHandler + Driver protocol dispatch).
- PhoenixTest.Playwright is a separate setup path (PhoenixTest.Playwright.Case) that injects a Playwright-backed conn/session struct.
- Both ecosystems dispatch behavior from session struct type/protocol implementation, not from a public mode atom argument.

## Recommendation

Yes, we can remove :static/:live from the public API surface, but not by deleting the concepts entirely.

- Keep explicit static/live selection as internal/test-only capability for conformance and regression isolation.
- Simplify public API to browser vs non-browser:
  - non-browser default entrypoint (auto switching semantics)
  - explicit browser entrypoint
- Match PhoenixTest direction by making dispatch struct-driven at runtime and minimizing public mode vocabulary.

## Proposed Migration Shape

1. Introduce public constructors that express only runtime class:
   - session(opts \\ []) => non-browser auto
   - browser_session(opts \\ []) (or equivalent explicit browser constructor)
2. Deprecate session(:static) and session(:live) for public callers.
3. Keep static/live constructors in internal/test helpers (for example test support module) so conformance suites can still pin drivers.
4. Keep Harness driver tags unchanged internally for now; revisit test-only driver naming after API simplification lands.
5. Update README and migration task messaging to remove :static/:live from user-facing guidance.

## Risks / Tradeoffs

- Removing :static/:live immediately without an internal replacement would reduce precision of conformance tests and weaken diagnostics.
- A staged deprecation avoids churn for existing users while converging to a simpler public story.

## Follow-up Implementation Tasks

- Add simplified public constructors (non-browser default + explicit browser constructor) and deprecation warnings for session(:static/:live).
- Introduce internal/test-only static/live constructors used by core conformance suites.
- Update README/API docs and migration task guidance to remove public :static/:live positioning.
- Add regression tests covering backward-compatible deprecation path and internal harness pinning.

## Log
- [x] Ran beans prime
- [x] Searched for existing bean
- [x] Audited mode usage in lib, README, and test/core tag matrix
- [x] Inspected upstream PhoenixTest (germsvel/phoenix_test, latest commit 2ed0788 on 2026-02-04)
- [x] Inspected upstream PhoenixTest.Playwright (ftes/phoenix_test_playwright, latest commit 9df308a on 2026-02-24)
- [x] Normalized bean markdown formatting and removed escaped newline artifacts

## Summary of Changes

- Created a research bean and audited current Cerberus mode usage in API, docs, and conformance tests.
- Verified that public API currently exposes :auto/:static/:live/:browser while harness defaults to :auto + :browser.
- Compared against upstream PhoenixTest and PhoenixTest.Playwright and confirmed their driver selection is struct/setup-driven rather than a public mode selector.
- Produced recommendation: remove :static/:live from public API in a staged deprecation, keep static/live pinning as internal test capability, and follow with docs/migration updates.
- Captured concrete follow-up implementation tasks.
- Fixed bean body formatting so sections render with proper newlines.
