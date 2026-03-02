# Migration Fixture Project

This nested Phoenix app is a deterministic migration fixture used by Cerberus tests.

It intentionally contains baseline pre-migration tests using PhoenixTest.

The migration verification runner copies this project to a temp directory, runs the
baseline tests, applies mix cerberus.migrate_phoenix_test, then runs the
rewritten tests.
