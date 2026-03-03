---
# cerberus-xqk5
title: Preserve comments in migration rewrites
status: completed
type: bug
priority: normal
created_at: 2026-03-02T14:01:29Z
updated_at: 2026-03-02T14:07:44Z
---

- [x] Investigate parser/emitter path that drops comments during migration rewrites\n- [x] Implement comment-preserving rewrite output\n- [x] Add regression test proving comments are preserved\n- [x] Run focused migration task tests

## Summary of Changes
Switched migration rewrite parse/emit from Code.string_to_quoted + Macro.to_string to Sourceror.parse_string + Sourceror.to_string, so comments are retained when files are rewritten.
Added Sourceror-AST compatibility helpers for keyword options and alias options to preserve prior rewrite/canonicalization behavior (including PhoenixTest.Assertions alias rewriting and text/with/option canonicalization).
Preserved comments when replacing conn-based visit pipelines by transferring leading/trailing comment metadata to the injected session() bootstrap node.
Added a regression test that rewrites a commented sample file and asserts comments remain after --write.
Verified with direnv exec . mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs (15 tests, 0 failures).
