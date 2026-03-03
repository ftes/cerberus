---
# cerberus-0j40
title: Fix Firefox BiDi preload scripts (remove skip + runtime helper checks)
status: todo
type: task
priority: normal
created_at: 2026-03-03T11:23:25Z
updated_at: 2026-03-03T11:30:33Z
parent: cerberus-dsr0
---

Replace the current Firefox-specific runtime helper preload checks with reliable preload-script installation for assertion/action helpers.\n\nScope:\n- [ ] Reproduce and characterize current Firefox preload-script failure modes\n- [ ] Implement robust preload-script setup path for Firefox user contexts\n- [ ] Remove Firefox per-call helper preload checks from browser driver action/assertion flows\n- [ ] Validate browser suites on Firefox and Chrome\n- [ ] Update docs/comments about Firefox preload behavior

\nAcceptance:\n- [ ] Remove or retire skip_firefox_problematic_preload?/2 for FF once BiDi preload is reliable\n- [ ] Ensure assertion/action/popup preload helpers are installed at context setup on FF, matching Chrome behavior\n- [ ] Keep helper-version invalidation semantics intact across browsers
