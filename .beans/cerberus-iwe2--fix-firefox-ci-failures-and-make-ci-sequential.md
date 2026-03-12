---
# cerberus-iwe2
title: Fix Firefox CI failures and make CI sequential
status: in-progress
type: bug
created_at: 2026-03-12T08:21:43Z
updated_at: 2026-03-12T08:21:43Z
---

Fix the Firefox CI failures from the new lane and change the workflow so Firefox runs as an extra sequential step in the main CI job.

- [ ] inspect failing Firefox tests and identify browser-specific assumptions
- [ ] fix tests or implementation for Firefox parity
- [ ] change CI workflow to run Firefox sequentially in the main CI job
- [ ] verify full local Firefox suite again
- [ ] summarize results and follow-ups
