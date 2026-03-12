---
# cerberus-84ws
title: Run EV2 Cerberus compare-copy suite under Firefox
status: completed
type: task
priority: normal
created_at: 2026-03-12T11:47:33Z
updated_at: 2026-03-12T11:52:27Z
---

Run the full EV2 Cerberus compare-copy suite in ../ev2-copy under Firefox, capture the failure set, and report the current status after the browser-driver hardening work.

\n\nRun log:\n- Command: source /Users/ftes/src/cerberus/.envrc && PATH=/Users/ftes/src/ev2-copy/tmp/test-bin:/Users/ftes/.codex/tmp/arg0/codex-arg0SwpUeZ:/Users/ftes/perl5/bin:/Applications/LibreOffice.app/Contents/MacOS:/Applications/Firefox.app/Contents/MacOS:/opt/homebrew/opt/libpq/bin:/Users/ftes/.local/bin:/opt/homebrew/Cellar/libpq/17.2/bin/:/Users/ftes/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pmk/env/global/bin:/Applications/Codex.app/Contents/Resources PORT=4386 CERBERUS_BROWSER_NAME=firefox mix test.cerberus.compare.copy\n- Workdir: /Users/ftes/src/ev2-copy\n- Result: 689 tests, 25 failures, 30 skipped, 5042 excluded\n- Duration: 267.0s\n- Main failure buckets: toast assertions on successful-looking flows, action helper is not available on later-page clicks, one browser readiness timeout after visit, and many DBConnection.OwnershipError logs under concurrent LiveView/browser load
