---
# cerberus-x72l
title: Reduce Firefox session-start pressure in EV2 full compare-copy runs
status: completed
type: bug
priority: normal
created_at: 2026-03-12T12:06:24Z
updated_at: 2026-03-12T12:44:00Z
---

Full ../ev2-copy Cerberus compare-copy runs under Firefox now fail primarily during browser session startup under suite concurrency. Investigate direct Firefox BiDi session limits/startup latency and reduce concurrent startup pressure or improve runtime reuse so full Firefox runs stop hitting session creation timeouts and Maximum number of active sessions.\n\n- [ ] measure session creation concurrency and failure threshold under EV2 full compare-copy load\n- [ ] choose and implement the smallest fix in Cerberus or EV2 harness\n- [ ] rerun the full Firefox compare-copy suite\n- [ ] summarize the outcome



Outcome on 2026-03-12:
- Moved local Firefox startup/teardown into Cerberus runtime so it owns the Port directly, aligned with the Chrome watchdog/kill-tree path.
- Added focused runtime coverage with a fake Firefox binary and verified normal runtime shutdown cleans up the browser process and restarts the runtime.
- Re-ran ../ev2-copy compare-copy under CERBERUS_BROWSER_NAME=firefox: 689 tests, 3 failures, 30 skipped, 5042 excluded, 303.2s.
- The previous Firefox session-start failures, including Maximum number of active sessions, did not reproduce.
- No leftover Firefox processes remained after the full EV2 Firefox run.
- Remaining failures are functional/assertion issues, not Firefox runtime startup pressure.
