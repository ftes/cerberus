---
# cerberus-vswy
title: Force LazyHTML as internal HTML representation
status: completed
type: task
created_at: 2026-03-07T06:32:50Z
updated_at: 2026-03-07T07:53:00Z
---

Convert Cerberus to use LazyHTML documents as the canonical internal HTML representation across shared HTML helpers and drivers, keeping raw strings only at ingress/egress boundaries.

- [x] Add shared parse/to_html helpers and convert OpenBrowser to document input
- [x] Expand LiveView client wrappers for tree/document access and thin LiveViewTest wrappers
- [x] Refactor Cerberus.Html and Cerberus.Phoenix.LiveViewHTML to be LazyHTML-only
- [x] Convert live and static driver state from html strings to document storage
- [x] Convert browser snapshot consumers to parse at the boundary and use LazyHTML internally
- [x] Update internal test support helpers and relevant tests
- [x] Run format and targeted tests
- [x] Run required precommit/test/slow sequence

## Log

- Added `Cerberus.Html.parse/1`, `parse!/1`, and `to_html/1`, then removed internal string overloads from `Cerberus.Html` and `Cerberus.Phoenix.LiveViewHTML`.
- Switched `Cerberus.OpenBrowser.write_snapshot!/3` to accept `LazyHTML.t()` and kept string serialization inside the snapshot boundary.
- Expanded `Cerberus.Phoenix.LiveViewClient` with document/tree helpers plus local `find_live_child/2`, `assert_redirect/*`, and `open_browser/2` wrappers.
- Converted live and static driver session state from `html` strings to `document` fields and updated browser snapshot handling to parse at the transport boundary.
- Updated fallback live submit logic to read form attributes from the `LazyHTML` document instead of regex scraping rendered HTML.
- Updated helper tests and support modules to use `LazyHTML` documents, then ran targeted coverage and the full `mix do format + precommit + test + test --only slow` sequence successfully.
