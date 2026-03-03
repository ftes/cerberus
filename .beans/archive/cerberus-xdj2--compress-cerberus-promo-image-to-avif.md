---
# cerberus-xdj2
title: Compress Cerberus promo image to AVIF
status: completed
type: task
priority: normal
created_at: 2026-03-03T12:35:44Z
updated_at: 2026-03-03T12:37:40Z
---

## Goal
Convert the provided Cerberus promo image to AVIF only.

## Todo
- [x] Locate the source image file
- [x] Encode AVIF output
- [x] Verify output size and quality
- [x] Record summary

## Summary of Changes
Converted docs/hero.png to docs/hero.avif using avifenc at quality 55 speed 4.
Verified dimensions remain 1536x1024 and file size dropped from 2697774 bytes to 129441 bytes.
