---
# cerberus-te2q
title: Compare slow Cerberus migrations against original tests
status: completed
type: task
priority: normal
created_at: 2026-03-08T07:00:52Z
updated_at: 2026-03-08T07:10:05Z
---

## Scope

- [x] Profile the migrated EV2 Cerberus suite and identify the slowest migrated files or tests.
- [x] Pick the easiest slow migrated files to compare, copy their Cerberus versions to *_cerberus_test.exs, and restore the original test files at the original paths.
- [x] Measure runtime of the restored originals versus the copied Cerberus versions.
- [x] Summarize the slowest Cerberus cases and the pre-migration speed comparison.

## Summary of Changes

Profiled whole-file migrated modules tagged with @moduletag :cerbrerus by running each file individually with MIX_ENV=test and a random PORT.

Slowest migrated Cerberus whole-file modules observed:
- /Users/ftes/src/ev2-copy/test/features/my_timecards_browser_test.exs: 25.7s
- /Users/ftes/src/ev2-copy/test/features/project_form_feature_test.exs: 19.7s
- /Users/ftes/src/ev2-copy/test/features/create_offer_test.exs: 19.3s
- /Users/ftes/src/ev2-copy/test/features/register_and_accept_offer_test.exs: 18.9s
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_test.exs: 16.4s
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/contacts_browser_test.exs: 16.4s

Picked three easy comparison targets and split them so both variants can coexist:
- /Users/ftes/src/ev2-copy/test/features/project_form_feature_test.exs restored to original committed Playwright version
- /Users/ftes/src/ev2-copy/test/features/project_form_feature_cerberus_test.exs copied from the migrated Cerberus version with a renamed module
- /Users/ftes/src/ev2-copy/test/features/register_and_accept_offer_test.exs restored to original committed Playwright version
- /Users/ftes/src/ev2-copy/test/features/register_and_accept_offer_cerberus_test.exs copied from the migrated Cerberus version with a renamed module
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_test.exs restored to original committed PhoenixTest version
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_cerberus_test.exs copied from the migrated Cerberus version with a renamed module

Side-by-side runtime comparison:
- project_form_feature
  - original Playwright: 4.9s
  - Cerberus copy: 19.2s
- register_and_accept_offer
  - original Playwright: 4.4s
  - Cerberus copy: 19.8s
- notifications
  - original PhoenixTest: 2.3s
  - Cerberus copy: 12.3s

Interpretation:
- For these easy restored comparisons, Cerberus is about 3.9x slower on project_form_feature, 4.5x slower on register_and_accept_offer, and 5.3x slower on notifications.
- The browser-heavy Cerberus files dominate the slow end, but even a non-browser live file like notifications shows a substantial regression versus PhoenixTest.
