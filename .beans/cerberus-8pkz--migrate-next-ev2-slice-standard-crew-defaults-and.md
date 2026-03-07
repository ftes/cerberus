---
# cerberus-8pkz
title: 'Migrate next EV2 slice: standard crew defaults and register offer'
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:28:49Z
updated_at: 2026-03-07T06:31:52Z
---

## Scope

- [x] Migrate test/features/edit_standard_crew_defaults_test.exs from PhoenixTest to Cerberus using ConnCase.
- [x] Migrate test/features/register_and_accept_offer_test.exs from Playwright to Cerberus browser sessions using UI flows.
- [x] Keep structured locator semantics in migrated assertions and actions where they improve debugging.
- [x] Run targeted MIX_ENV=test verification in /Users/ftes/src/ev2-copy with random PORT values.

## Notes

Read /Users/ftes/src/cerberus/MIGRATE_FROM_PHOENIX_TEST.md first. Reuse Browser.evaluate_js if needed for the page accessibility audit instead of Playwright frame APIs.

## Summary of Changes

Migrated test/features/edit_standard_crew_defaults_test.exs to ConnCase plus Cerberus session(conn), tagged it with :cerbrerus, and kept the recalculation behavior assertions centered on the Oban queue rather than transient live toasts.

Migrated test/features/register_and_accept_offer_test.exs to ConnCase browser sessions with UI login, sandbox metadata via Browser.user_agent_for_sandbox, and Cerberus browser interactions end to end. The browser rewrite kept the user-facing flow intact: PM sends the offer, recipient creates an account from the emailed CTA, verifies email, logs in, opens the offer, accepts it, and checks accessibility at the same checkpoints as before. The Playwright frame-based accessibility audit was replaced with Browser.evaluate_js plus axe JSON decoding, which works cleanly with Cerberus browser sessions.

Verification:
- cd /Users/ftes/src/ev2-copy && eval $(direnv export zsh) && PORT=5033 MIX_ENV=test mix test test/features/edit_standard_crew_defaults_test.exs test/features/register_and_accept_offer_test.exs --include integration
- Result: 2 tests, 0 failures
