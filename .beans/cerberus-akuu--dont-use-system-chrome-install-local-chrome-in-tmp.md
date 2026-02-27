---
# cerberus-akuu
title: Don't use system Chrome; install local Chrome in /tmp with pinned matching ChromeDriver
status: completed
type: task
priority: normal
created_at: 2026-02-27T10:12:51Z
updated_at: 2026-02-27T15:59:10Z
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
- [x] Browser runtime never calls system Chrome binary.
- [x] Pinned Chrome version is documented and reproducible.
- [x] ChromeDriver version matches pinned Chrome version/build.
- [x] Validation command/check reports both versions and passes only when matched.

## Summary of Changes
- Reworked `bin/check_bidi_ready.sh --install` to provision pinned Chrome for Testing and matching ChromeDriver under `tmp/browser-tools`.
- Enforced major+build parity checks and strict pinned-version checks in install mode.
- Added generated `tmp/browser-tools/env.sh` export output for reproducible local wiring.
- Updated `.envrc` to use pinned local `/tmp` browser runtime paths (platform-aware), removing system Chrome defaults.
- Updated README browser runtime docs with pinned version and install/validation workflow.
- Verified with `bin/check_bidi_ready.sh --install` that `POST /session` returns a non-empty BiDi `webSocketUrl`.
