---
# cerberus-vdxb
title: Investigate CI Chrome session startup failure in CoreSelectChooseBehaviorTest
status: completed
type: bug
priority: normal
created_at: 2026-03-01T16:07:43Z
updated_at: 2026-03-01T16:12:44Z
---

Investigate Actions run 22546929628 job 65310712085 failure where browser driver initialization failed before test execution with Chrome session not created. Determine if flaky infra issue vs deterministic test/runtime bug and propose mitigation if needed.

## Todo
- [x] Inspect failing test and harness execution path
- [x] Reproduce locally (including repeated runs) and classify failure mode
- [x] Identify likely CI-specific root cause(s) and evidence
- [x] Recommend mitigation and whether test should be considered flaky

## Summary of Changes
- Pulled full CI logs for run 22546929628 job 65310712085 and confirmed failure happens during browser driver initialization (Chrome session creation), before test assertions execute.
- Verified the failing test itself is a normal LiveView/browser scenario with repeated select calls, and failure originates at browser session startup in Browser.new_session/1.
- Confirmed Chrome and chromedriver versions were matched in CI (146.0.7680.31) and browser runtime install succeeded before test execution.
- Compared neighboring runs: a later CI run passed Chrome+Firefox suites with the same sandbox warning lines, suggesting the warning is not the root cause and this failure is likely intermittent startup instability.
- Scanned recent failed CI runs for the same Chrome instance exited signature; this exact startup failure appears isolated in the checked window.
