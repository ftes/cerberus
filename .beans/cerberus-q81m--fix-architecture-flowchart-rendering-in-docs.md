---
# cerberus-q81m
title: Fix architecture flowchart rendering in docs
status: completed
type: bug
priority: normal
created_at: 2026-03-04T13:02:27Z
updated_at: 2026-03-04T13:05:07Z
---

## Goal

Fix the Architecture and Driver Model flowchart rendering so Mermaid diagrams render correctly in generated docs.

## Todo

- [x] Locate source flowchart block and identify markdown/rendering issue
- [x] Update docs source to valid Mermaid fenced block
- [x] Regenerate docs and confirm flowchart renders
- [x] Summarize and close bean

## Summary of Changes

- Updated the Layering diagram in docs architecture guide to strict Mermaid-compatible node labels using quoted labels and br line breaks.
- Kept the diagram as a Mermaid fenced block so ExDoc emits a mermaid code block for client-side rendering.
- Regenerated docs with mix docs and verified architecture.html contains the Mermaid block with updated syntax.
