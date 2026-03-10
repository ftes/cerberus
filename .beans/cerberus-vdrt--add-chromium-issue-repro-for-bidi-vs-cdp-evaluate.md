---
# cerberus-vdrt
title: Add Chromium issue repro for BiDi vs CDP evaluate
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:09:24Z
updated_at: 2026-03-10T16:13:06Z
---

## Goal

Create a single-file benchmark snippet suitable for a Chromium issue that compares ChromeDriver BiDi script.evaluate against direct CDP Runtime.evaluate on the same Chrome session.

## Todo

- [x] Inspect current Cerberus evaluate payloads and env conventions
- [x] Add a standalone benchmark snippet using CHROME and CHROMEDRIVER env vars
- [x] Run the snippet locally and record representative output
- [x] Update the bean with a summary of changes

## Summary of Changes

Added a standalone Node benchmark at `bench/chromium_bidi_vs_cdp_evaluate.js` that launches ChromeDriver from `CHROMEDRIVER`, launches Chrome from `CHROME`, creates a single session, and compares raw BiDi `script.evaluate` against raw CDP `Runtime.evaluate` on the same page target.

Validated locally with Chrome for Testing 146.0.7680.31 / matching ChromeDriver. A 200-iteration run with a small object-returning expression measured roughly 0.282ms mean for CDP and 1.963ms mean for BiDi, for a ~6.96x mean slowdown and ~3.05x median slowdown on this machine.
