import Config

alias Cerberus.Fixtures.Endpoint

config :cerberus, Endpoint,
  server: true,
  http: [port: "PORT" |> System.get_env("4002") |> String.to_integer()],
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub

config :cerberus, :browser,
  show_browser: System.get_env("SHOW_BROWSER", "false") == "true",
  chrome_binary: System.fetch_env!("CHROME"),
  chromedriver_binary: System.fetch_env!("CHROMEDRIVER")

config :cerberus, :endpoint, Endpoint

config :logger, level: :error
