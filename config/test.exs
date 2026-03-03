import Config

alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

config :cerberus, Endpoint,
  server: true,
  http: [port: System.get_env("PORT", "4002")],
  hostname: "localhost",
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub

config :cerberus, Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "127.0.0.1"),
  port: 5432,
  database: System.get_env("POSTGRES_DB", "cerberus_test#{System.get_env("MIX_TEST_PARTITION")}"),
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cerberus,
  browser: [
    show_browser: System.get_env("SHOW_BROWSER", "false") == "true",
    chrome_args: ["--disable-setuid-sandbox", "--disable-dev-shm-usage"]
  ],
  endpoint: Endpoint,
  sql_sandbox: true,
  ecto_repos: [Repo]

config :logger, level: :error
