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
- `/search/profile/a`, `/search/profile/b`, and `/search/profile/results` (static): alternate-form-shape fixture for stale-field pruning conformance across static/browser drivers.
- `/browser/extensions` (static): browser-only extension fixture for screenshot, keyboard, dialog, drag, and cookie helpers.
- `/session/user` and `/session/user/:value` (static): deterministic cookie/session sharing fixture for multi-user and multi-tab conformance.
- `/live/counter` (live): deterministic counter with `Increment` button.
- `/live/sandbox/messages` (live): DB-backed fixture with refresh click event.
- `/redirect/static` (static redirect): redirects to `/articles`.
- `/redirect/live` (static redirect): redirects to `/live/counter`.
- `/live/redirects` (live): link/button navigation fixture for navigate/patch/redirect parity, including `phx-click` JS command variants (`push`, `navigate`, `patch`, mixed pipelines, dispatch-only).
- `/live/redirect-return` (live): immediate live redirect-back fixture with flash.
- `/live/form-change` (live): `phx-change` fixture for `_target` payload semantics, no-change forms, and hidden-input ordering checks.
- `/live/form-sync` (live): dynamic/conditional form synchronization fixture for stale-field pruning, submit-only forms, and `JS.dispatch("change")` add/remove flows.
- `/live/trigger-action` (live): `phx-trigger-action` fixture for static POST handoff, patch sequencing, dynamic forms, and ambiguity handling.
- `/trigger-action/result` (static POST): deterministic sink page echoing trigger-action payloads and HTTP method.
- `/live/selector-edge` (live): duplicate button-label fixture for selector disambiguation checks.
- `/live/nested` (live): nested LiveView fixture for scoped `within/3` stack + child-isolation conformance.
- `/oracle/mismatch` (static): mismatch marker fixture for browser-oracle diff tests.
- `/live/oracle/mismatch` (live): mismatch marker fixture for browser-oracle diff tests.

## Shared Definitions

Route paths and fixture text constants are centralized in `Cerberus.Fixtures`.
Driver adapters and tests should reuse these helpers to avoid semantic drift.
