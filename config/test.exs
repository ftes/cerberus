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

env_value = fn key ->
  case System.get_env(key) do
    value when is_binary(value) and value != "" -> value
    _ -> nil
  end
end

chrome_version = env_value.("CERBERUS_CHROME_VERSION")
firefox_version = env_value.("CERBERUS_FIREFOX_VERSION")
geckodriver_version = env_value.("CERBERUS_GECKODRIVER_VERSION")

chrome_binary_from_version =
  case chrome_version do
    version when is_binary(version) -> Path.join([File.cwd!(), "tmp", "chrome-#{version}", "chrome"])
    _ -> nil
  end

chromedriver_binary_from_version =
  case chrome_version do
    version when is_binary(version) -> Path.join([File.cwd!(), "tmp", "chromedriver-#{version}", "chromedriver"])
    _ -> nil
  end

firefox_binary_from_version =
  case firefox_version do
    version when is_binary(version) -> Path.join([File.cwd!(), "tmp", "firefox-#{version}", "firefox"])
    _ -> nil
  end

geckodriver_binary_from_version =
  case geckodriver_version do
    version when is_binary(version) -> Path.join([File.cwd!(), "tmp", "geckodriver-#{version}", "geckodriver"])
    _ -> nil
  end

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
  browser_name: if(System.get_env("CERBERUS_BROWSER_NAME") == "firefox", do: :firefox, else: :chrome),
  show_browser: System.get_env("SHOW_BROWSER", "false") == "true",
  chrome_webdriver_url: env_value.("WEBDRIVER_URL_CHROME"),
  firefox_webdriver_url: env_value.("WEBDRIVER_URL_FIREFOX"),
  webdriver_url: env_value.("WEBDRIVER_URL"),
  chrome_binary: env_value.("CHROME") || chrome_binary_from_version,
  chromedriver_binary: env_value.("CHROMEDRIVER") || chromedriver_binary_from_version,
  firefox_binary: env_value.("FIREFOX") || firefox_binary_from_version,
  geckodriver_binary: env_value.("GECKODRIVER") || geckodriver_binary_from_version

config :cerberus, :endpoint, Endpoint
config :cerberus, :sql_sandbox, true
config :cerberus, ecto_repos: [Repo]

config :logger, level: :error
