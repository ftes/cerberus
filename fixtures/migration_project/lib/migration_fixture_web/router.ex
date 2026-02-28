defmodule MigrationFixtureWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", MigrationFixtureWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/search", PageController, :search)
    get("/search/results", PageController, :search_results)
    live("/counter", CounterLive, :index)
  end
end
