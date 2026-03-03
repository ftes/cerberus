import Config

alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

base_url_host = System.get_env("CERBERUS_BASE_URL_HOST", "localhost")
env_int = fn key, default -> key |> System.get_env(Integer.to_string(default)) |> String.to_integer() end
partition_env = System.get_env("MIX_TEST_PARTITION")
test_partition = env_int.("MIX_TEST_PARTITION", 1)
partition_suffix = if partition_env in [nil, ""], do: "", else: partition_env
default_port = 4_001 + test_partition

show_browser? = String.downcase(System.get_env("SHOW_BROWSER", "false")) in ["1", "true", "yes", "on"]
chrome_webdriver_url = System.get_env("WEBDRIVER_URL_CHROME")

config :cerberus, Endpoint,
  server: true,
  http: [port: env_int.("PORT", default_port)],
  url: [host: base_url_host],
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub

config :cerberus, Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "127.0.0.1"),
  port: env_int.("POSTGRES_PORT", 5_432),
  database: System.get_env("POSTGRES_DB", "cerberus_test#{partition_suffix}"),
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cerberus, :browser,
  browser_name: :chrome,
  show_browser: show_browser?,
  chrome_args: ["--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  chrome_webdriver_url: chrome_webdriver_url,
  webdriver_url: chrome_webdriver_url || System.get_env("WEBDRIVER_URL")

config :cerberus, :endpoint, Endpoint
config :cerberus, :sql_sandbox, true
config :cerberus, ecto_repos: [Repo]

config :logger, level: :error
