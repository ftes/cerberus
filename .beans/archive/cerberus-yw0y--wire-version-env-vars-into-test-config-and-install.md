---
# cerberus-yw0y
title: Wire version env vars into test config and install scripts
status: completed
type: task
priority: normal
created_at: 2026-03-01T09:45:51Z
updated_at: 2026-03-01T09:50:59Z
---

Align browser binary path resolution with version env vars across config and scripts.

- [x] update config/test.exs to construct binary paths from version env vars
- [x] make bin/chrome.sh respect CERBERUS_CHROME_VERSION while keeping --version override
- [x] make bin/firefox.sh respect CERBERUS_FIREFOX_VERSION and CERBERUS_GECKODRIVER_VERSION while keeping arg overrides
- [x] run mix format and mix precommit

- [x] expose stable executable paths in tmp (chrome, chromedriver, firefox, geckodriver) and align config path resolution

## Summary of Changes

- Added stable executable entrypoints in install scripts: tmp/chrome-<version>/chrome, tmp/chromedriver-<version>/chromedriver, tmp/firefox-<version>/firefox, and tmp/geckodriver-<version>/geckodriver.
- Updated config/test.exs to derive browser and driver binary paths directly from CERBERUS_CHROME_VERSION, CERBERUS_FIREFOX_VERSION, and CERBERUS_GECKODRIVER_VERSION using those stable paths, while preserving explicit CHROME, CHROMEDRIVER, FIREFOX, and GECKODRIVER overrides.
- Added top-level per-browser remote webdriver config keys chrome_webdriver_url and firefox_webdriver_url, and updated runtime resolution to support them with compatibility fallback to webdriver_urls and webdriver_url.
- Updated runtime tests and docs to reflect per-browser top-level webdriver URL keys and env/arg version behavior.
- Ran mix format, targeted runtime tests, and mix precommit successfully.
