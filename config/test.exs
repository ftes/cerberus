import Config

alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

sandbox_db_path = Path.expand("../tmp/cerberus_test.sqlite3", __DIR__)

config :cerberus, Endpoint,
  server: true,
  http: [port: "PORT" |> System.get_env("4002") |> String.to_integer()],
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub

config :cerberus, Repo,
  database: sandbox_db_path,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cerberus, :browser,
  show_browser: System.get_env("SHOW_BROWSER", "false") == "true",
  chrome_binary: System.fetch_env!("CHROME"),
  chromedriver_binary: System.fetch_env!("CHROMEDRIVER")

config :cerberus, :endpoint, Endpoint
config :cerberus, :sql_sandbox, true
config :cerberus, ecto_repos: [Repo]

config :logger, level: :error
