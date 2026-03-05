---
# cerberus-uni0
title: Better option selected assertion handling in static/live snapshots
status: in-progress
type: bug
priority: normal
created_at: 2026-03-05T13:49:26Z
updated_at: 2026-03-05T14:09:46Z
---

Problem pattern: assert_has("select[name='x'] option[value='y'][selected]"). In Live/static render paths, selected state may come from form value/state and not always explicit selected attribute in HTML snapshots. Improve assertion matching to respect effective selected state.
