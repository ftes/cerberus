---
# cerberus-z4cm
title: Support browser read assertions while a dialog is open
status: completed
type: bug
priority: normal
created_at: 2026-03-09T10:29:55Z
updated_at: 2026-03-09T10:41:06Z
---

## Scope

- [ ] Reproduce the current blocked-dialog read assertion failure under the Chrome + ChromeDriver + Bibbidi transport stack.
- [ ] Decide whether browser read assertions should auto-unblock dialogs or switch to a different explicit contract.
- [ ] Implement the chosen behavior cleanly in the browser driver transport path.
- [x] Add regression coverage for text/path/assertion reads with alert, confirm, and prompt dialogs already open.

## Notes

This is the currently skipped/unsupported gap surfaced during the Chrome-only runtime simplification pass: eval-backed browser read assertions still time out when a modal dialog is already open.

## Summary of Changes

Browser evaluate requests now run asynchronously inside the user-context and browsing-context processes so dialog events can still be handled while a modal blocks the underlying browser command. This re-enabled the previously skipped slow regression coverage for alert and prompt dialog reads and restored the assertion on the post-dialog result path.
