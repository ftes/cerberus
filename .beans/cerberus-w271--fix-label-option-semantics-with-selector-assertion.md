---
# cerberus-w271
title: Fix label option semantics with selector assertions
status: in-progress
type: bug
created_at: 2026-03-05T14:09:46Z
updated_at: 2026-03-05T14:09:46Z
---

Add regression tests derived from EV2 shim skips for assert_has with selector + label filters (e.g. input[disabled] label: Foo) and make core assertion matching label-to-control aware instead of same-node label text matching.
