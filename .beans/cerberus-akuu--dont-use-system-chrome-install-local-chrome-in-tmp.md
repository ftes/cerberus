---
# cerberus-akuu
title: Don't use system Chrome; install local Chrome in /tmp with pinned matching ChromeDriver
status: todo
type: task
created_at: 2026-02-27T10:12:51Z
updated_at: 2026-02-27T10:12:51Z
parent: cerberus-sfku
blocking:
    - cerberus-k4m0
---

## Objective
Provision a local Chrome runtime under `/tmp` and avoid using any system-installed Chrome.

## Requirements
- Install Chrome into a project-scoped path in `/tmp`.
- Pin Chrome version explicitly (no floating latest).
- Install ChromeDriver that exactly matches the pinned Chrome version/build.
- Ensure runtime wiring uses the local Chrome binary path, not system Chrome discovery.
- Add a validation step that fails fast on browser/driver mismatch.

## Acceptance
- [ ] Browser runtime never calls system Chrome binary.
- [ ] Pinned Chrome version is documented and reproducible.
- [ ] ChromeDriver version matches pinned Chrome version/build.
- [ ] Validation command/check reports both versions and passes only when matched.
