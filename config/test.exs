import Config

alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

browser_name =
  case System.get_env("CERBERUS_BROWSER_NAME") do
    nil ->
      :chrome

    value when is_binary(value) ->
      case value |> String.trim() |> String.downcase() do
        "chrome" -> :chrome
        "firefox" -> :firefox
      end
  end

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
    browser_name: browser_name,
    headless: String.downcase(System.get_env("HEADLESS", "true")) not in ["0", "false", "no", "off"],
    chrome_args: ["--disable-setuid-sandbox", "--disable-dev-shm-usage"],
    max_concurrent_tests: max(div(System.schedulers_online(), 2), 1)
  ],
  endpoint: Endpoint,
  profiling: String.downcase(System.get_env("CERBERUS_PROFILE_COMPILE", "false")) in ["1", "true", "yes", "on"],
  sql_sandbox: true,
  ecto_repos: [Repo]

config :logger, level: :error
