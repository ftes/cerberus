defmodule Cerberus.Fixtures.Router do
  @moduledoc false
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", Cerberus.Fixtures do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/articles", PageController, :articles)
    get("/redirect/static", PageController, :redirect_static)
    get("/redirect/live", PageController, :redirect_live)
    get("/oracle/mismatch", PageController, :oracle_mismatch)

    live_session :fixtures, root_layout: {Cerberus.Fixtures.Layouts, :root} do
      live("/live/counter", CounterPageLive)
      live("/live/redirects", RedirectsLive)
      live("/live/oracle/mismatch", OracleMismatchLive)
    end
  end
end
