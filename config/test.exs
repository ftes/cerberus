import Config

alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

test_instance =
  System.get_env("CERBERUS_TEST_INSTANCE") ||
    "pid" <> List.to_string(:os.getpid())

default_port =
  4_002 +
    rem(
      :erlang.phash2(test_instance),
      1_000
    )

config :cerberus, Endpoint,
  server: true,
  http: [port: "PORT" |> System.get_env(Integer.to_string(default_port)) |> String.to_integer()],
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub

config :cerberus, Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "127.0.0.1"),
  port: "POSTGRES_PORT" |> System.get_env("5432") |> String.to_integer(),
  database: System.get_env("POSTGRES_DB", "cerberus_test_#{test_instance}"),
  maintenance_database: System.get_env("POSTGRES_MAINTENANCE_DB", "postgres"),
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cerberus, :browser,
  show_browser: System.get_env("SHOW_BROWSER", "false") == "true",
  webdriver_url: System.get_env("WEBDRIVER_URL"),
  chrome_binary: System.get_env("CHROME"),
  chromedriver_binary: System.get_env("CHROMEDRIVER"),
  firefox_binary: System.get_env("FIREFOX"),
  geckodriver_binary: System.get_env("GECKODRIVER")

config :cerberus, :endpoint, Endpoint
config :cerberus, :sql_sandbox, true
config :cerberus, ecto_repos: [Repo]

config :logger, level: :error
