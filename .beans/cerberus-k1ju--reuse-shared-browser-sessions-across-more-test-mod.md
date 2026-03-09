---
# cerberus-k1ju
title: Reuse shared browser sessions across more test modules
status: completed
type: task
priority: normal
created_at: 2026-03-09T14:52:59Z
updated_at: 2026-03-09T14:56:41Z
---

## Scope

- [ ] Audit browser-oriented test modules for repeated per-test browser session setup.
- [ ] Convert the safe modules to shared setup_all browser sessions with per-test reset helpers where needed.
- [ ] Leave isolation-sensitive modules on fresh sessions and note why.
- [ ] Re-run targeted browser module coverage plus full test and slow lanes.
- [x] Record which modules changed and the before/after runtime impact.

## Summary of Changes

- Audited the direct browser-session call sites and converted the safe repeated-session modules to shared setup_all browser sessions.
- Updated BrowserTimeoutAssertionsTest and BrowserTagShowcaseTest to reuse one module browser session; updated DocumentationExamplesTest so the evaluate_js browser snippet reuses the existing shared browser session.
- Left intentionally isolated browser contexts in place for modules whose contract depends on fresh sessions or multiple independent browser contexts, including cross-driver multi-user/multi-tab coverage, popup/multi-session behavior, timeout constructor assertions, and the auto-mode single browser row.
- Verified targeted coverage plus full regular and slow lanes. The slow lane improved from 16.7s to 16.0s.
