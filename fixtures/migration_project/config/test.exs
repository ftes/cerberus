import Config

config :logger, level: :warning

config :migration_fixture, MigrationFixtureWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4017],
  server: true

config :phoenix, :plug_init_mode, :runtime

config :phoenix_test,
  endpoint: MigrationFixtureWeb.Endpoint,
  otp_app: :migration_fixture
