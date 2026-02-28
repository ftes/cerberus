defmodule MigrationFixtureWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :browser_no_csrf do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
  end

  scope "/", MigrationFixtureWeb do
    pipe_through(:browser_no_csrf)

    post("/upload/result", PageController, :upload_result)
  end

  scope "/", MigrationFixtureWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/search", PageController, :search)
    get("/search/results", PageController, :search_results)
    get("/select", PageController, :select_page)
    get("/select/result", PageController, :select_result)
    get("/choose", PageController, :choose_page)
    get("/choose/result", PageController, :choose_result)
    get("/upload", PageController, :upload_page)
    get("/checkbox", PageController, :checkbox)
    get("/checkbox/save", PageController, :checkbox_save)
    get("/session-counter", PageController, :session_counter)
    get("/session-counter/increment", PageController, :session_counter_increment)
    live("/counter", CounterLive, :index)
    live("/live-nav", LiveNavLive, :index)
    live("/live-change", LiveChangeLive, :index)
    live("/live-async", LiveAsyncLive, :index)
  end
end
