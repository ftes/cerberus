---
# cerberus-2mhe
title: Assess removing browser versions from .envrc
status: completed
type: task
priority: normal
created_at: 2026-03-12T09:27:06Z
updated_at: 2026-03-12T09:27:16Z
---

Check whether Cerberus still needs CERBERUS_CHROME_VERSION and CERBERUS_FIREFOX_VERSION in .envrc after install-task defaults were added, and summarize the impact of removing them.

## Summary of Changes

- confirmed the Mix install tasks no longer require `CERBERUS_CHROME_VERSION` or `CERBERUS_FIREFOX_VERSION` in `.envrc` because they now fall back to Cerberus-pinned defaults
- confirmed `.envrc` still uses both vars to build explicit `CHROME`, `CHROMEDRIVER`, and `FIREFOX` paths
- confirmed CI still loads both vars from `.envrc` and uses them in the browser-runtime cache key
- conclusion: the version exports cannot be removed from `.envrc` yet without changing `.envrc` path resolution and CI cache keying
