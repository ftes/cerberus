import Config

config :migration_fixture, MigrationFixtureWeb.Endpoint,
  url: [host: "127.0.0.1"],
  secret_key_base: String.duplicate("a", 64),
  render_errors: [
    formats: [html: MigrationFixtureWeb.ErrorHTML, json: MigrationFixtureWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MigrationFixture.PubSub,
  live_view: [signing_salt: "migrationfixture"]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
