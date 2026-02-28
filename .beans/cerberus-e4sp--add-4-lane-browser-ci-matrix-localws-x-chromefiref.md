---
# cerberus-e4sp
title: Add 4-lane browser CI matrix (local/ws x chrome/firefox)
status: in-progress
type: task
created_at: 2026-02-28T20:40:01Z
updated_at: 2026-02-28T20:40:01Z
---

Restructure CI to run browser-tagged tests in four lanes: local chrome, local firefox, websocket chrome, websocket firefox. Minimize duplicate setup via shared non-browser setup and reusable matrix job steps.
