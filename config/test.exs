import Config

alias Cerberus.Fixtures.Endpoint

port =
  "PORT"
  |> System.get_env("4101")
  |> String.to_integer()

show_browser =
  "SHOW_BROWSER"
  |> System.get_env("false")
  |> String.downcase()
  |> Kernel.in(["1", "true", "yes", "on"])

config :cerberus, Endpoint,
  server: true,
  http: [ip: {127, 0, 0, 1}, port: port],
  url: [host: "127.0.0.1", port: port],
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub

config :cerberus, :base_url, "http://127.0.0.1:#{port}"

config :cerberus, :browser,
  show_browser: show_browser,
  chrome_binary: System.fetch_env!("CHROME"),
  chromedriver_binary: System.fetch_env!("CHROMEDRIVER")

config :cerberus, :endpoint, Endpoint
