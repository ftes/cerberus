defmodule Cerberus.Fixtures.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :cerberus

  @session_options [
    store: :cookie,
    key: "_cerberus_fixture_key",
    signing_salt: "fixture-signing-salt",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [:user_agent, session: @session_options]],
    longpoll: [connect_info: [:user_agent, session: @session_options]]
  )

  if Application.compile_env(:cerberus, :sql_sandbox, false) do
    plug(Phoenix.Ecto.SQL.Sandbox)
  end

  plug(Plug.Static,
    at: "/",
    from: :cerberus,
    only: ~w(assets)
  )

  plug(Plug.Static,
    at: "/",
    from: {:phoenix, "priv/static"},
    only: ~w(favicon.ico phoenix.min.js)
  )

  plug(Plug.Static,
    at: "/",
    from: {:phoenix_live_view, "priv/static"},
    only: ~w(phoenix_live_view.min.js)
  )

  plug(Plug.RequestId)
  plug(Plug.Session, @session_options)
  plug(Cerberus.Fixtures.Router)
end
