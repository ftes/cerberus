---
# cerberus-sl7c
title: Enable actual Mermaid rendering in generated docs
status: completed
type: bug
priority: normal
created_at: 2026-03-04T13:12:18Z
updated_at: 2026-03-04T13:14:24Z
---

## Goal

Make Mermaid diagrams render as diagrams in generated ExDoc HTML (not plain code blocks).

## Todo

- [x] Inspect current ExDoc docs config and generated HTML assets
- [x] Validate ExDoc Mermaid setup requirements from official docs
- [x] Update docs config/assets for Mermaid runtime loading and init
- [x] Regenerate docs and verify rendered output in browser-like execution
- [x] Summarize changes and close bean

## Summary of Changes

- Confirmed root cause: docs had Mermaid code blocks but no Mermaid runtime/init script in ExDoc output, so blocks rendered as plain code.
- Followed ExDoc official Mermaid guidance and added before_closing_body_tag in docs config to inject Mermaid CDN script plus exdoc loaded render hook.
- Regenerated docs with mix docs and verified architecture page includes Mermaid script/init.
- Verified in an actual browser engine by running headless Chrome against doc architecture html and confirming the flowchart is rendered to inline SVG with id mermaid graph 0.
