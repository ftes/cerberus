---
# cerberus-0o0q
title: Defer Playwright-style hit-target and stability checks
status: todo
type: task
priority: deferred
created_at: 2026-03-04T06:42:31Z
updated_at: 2026-03-04T06:42:31Z
---

Implement full Playwright-style actionability parity for browser actions after current scroll+visibility baseline is proven stable.

## Deferred Scope
- Hit-target / receives-events check: verify the actionable point resolves to the same element (or expected subtree) via hit-testing before click-like actions.
- Stability check: verify the element's bounding box is stable across animation frames before action to avoid clicking moving targets.

## Why These Checks Exist (Playwright model)
Playwright's actionability model includes checks beyond visibility, specifically that the element:
- is visible,
- is stable,
- receives pointer events at the action point,
- and is enabled where applicable.
References:
- https://playwright.dev/docs/actionability
- https://playwright.dev/docs/input

## Why We Deferred
- Complexity/maintenance tradeoff: hit-target and stability checks require frame-sampled geometry and elementFromPoint-style hit-testing logic with careful edge-case handling (overlays, transforms, fixed headers, animations).
- False-negative risk: strict hit-target logic can reject legitimate app patterns (temporary overlays, transitions, sticky UI) unless tuned with nuanced exceptions.
- Immediate value sequencing: scrollIntoView + basic visibility provides the largest reliability gain now with low semantic risk and no extra Elixir<->browser roundtrip.
- Measurement-first approach: defer advanced checks until we observe residual flakes that are clearly attributable to moving/intercepted targets.

## Trigger to Revisit
- Re-open when we see recurring click/submit flakes that remain after scroll+visibility and are attributable to intercepted clicks or moving elements.
