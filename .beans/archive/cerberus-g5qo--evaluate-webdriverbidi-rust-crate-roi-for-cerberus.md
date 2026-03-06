---
# cerberus-g5qo
title: Evaluate webdriverbidi Rust crate ROI for Cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-05T20:02:12Z
updated_at: 2026-03-05T20:05:00Z
---

## Goal
Decide whether adopting the Rust webdriverbidi crate is worthwhile versus keeping an in-house BiDi client.

## Todo
- [x] Measure current Cerberus WebDriver BiDi protocol surface from code
- [x] Assess webdriverbidi crate maturity and stability from primary sources
- [x] Recommend adopt vs avoid with complexity/stability tradeoffs

## Summary of Changes
Measured in-repo BiDi usage (15 unique commands across 7 domains, 7 subscribed events) and verified non-BiDi handshake endpoints. Collected current crates.io and GitHub metrics for webdriverbidi (latest version and recency, download counts, repo activity), plus declared module coverage from the crate README. Produced recommendation focused on whether crate adoption materially reduces complexity for Cerberus.
