# Cerberus Fixture Surface

Cerberus conformance tests run against deterministic internal fixtures.
The fixture app is started from `test/test_helper.exs` and serves only local routes.

## Endpoint

- module: `Cerberus.Fixtures.Endpoint`
- host: `127.0.0.1`
- port: `4101`
- network scope: local only (no external network dependencies)

## Routes

- `/articles` (static): visible text variants + hidden helper text + link to live counter.
- `/main` (static): non-live destination fixture with echoed `x-custom-header`.
- `/sandbox/messages` (static): DB-backed fixture page listing sandbox-visible rows.
- `/scoped` (static): duplicated link text across scoped sections for `within/3` conformance.
- `/search` and `/search/results` (static): deterministic query form flow.
- `/live/counter` (live): deterministic counter with `Increment` button.
- `/live/sandbox/messages` (live): DB-backed fixture with refresh click event.
- `/redirect/static` (static redirect): redirects to `/articles`.
- `/redirect/live` (static redirect): redirects to `/live/counter`.
- `/live/redirects` (live): link/button navigation fixture for navigate/patch/redirect parity.
- `/live/redirect-return` (live): immediate live redirect-back fixture with flash.
- `/live/selector-edge` (live): duplicate button-label fixture for selector disambiguation checks.
- `/oracle/mismatch` (static): mismatch marker fixture for browser-oracle diff tests.
- `/live/oracle/mismatch` (live): mismatch marker fixture for browser-oracle diff tests.

## Shared Definitions

Route paths and fixture text constants are centralized in `Cerberus.Fixtures`.
Driver adapters and tests should reuse these helpers to avoid semantic drift.
