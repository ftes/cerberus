---
# cerberus-lmpn
title: Handle BiDi transport errors during browser session startup
status: completed
type: bug
priority: normal
created_at: 2026-03-14T20:35:12Z
updated_at: 2026-03-14T20:38:00Z
---

Prevent browser driver startup from crashing when the BiDi layer returns Mint transport errors, and preserve a useful error for callers without assuming the payload is enumerable.

## Notes
- browser startup was crashing in lib/cerberus/driver/browser/bidi.ex because normalize_response treated %Mint.TransportError{} like a plain map and stringify_map_keys used Map.new on the struct
- fixed BiDi response normalization to convert structs through Map.from_struct before stringifying keys, and to recurse through nested structs as well, so transport errors now surface as ordinary browser init failures instead of Protocol.UndefinedError

## Summary of Changes
- fixed BiDi response normalization so Mint transport error structs and other nested structs are converted through Map.from_struct before key stringification, preventing browser startup from crashing with Protocol.UndefinedError
- verified the original failure sites now pass with source .envrc and fresh test ports: test/cerberus/timeout_defaults_test.exs and test/cerberus/playwright_performance_benchmark_test.exs
