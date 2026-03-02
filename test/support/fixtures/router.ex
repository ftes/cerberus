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

  pipeline :browser_no_csrf do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_secure_browser_headers)
  end

  scope "/", Cerberus.Fixtures do
    pipe_through(:browser_no_csrf)

    post("/trigger-action/result", PageController, :trigger_action_result)
    post("/upload/static/result", PageController, :static_upload_result)
  end

  scope "/", Cerberus.Fixtures do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/articles", PageController, :articles)
    get("/main", PageController, :main)
    get("/sandbox/messages", PageController, :sandbox_messages)
    get("/scoped", PageController, :scoped)
    get("/search", PageController, :search_form)
    get("/search/results", PageController, :search_results)
    get("/search/nested/results", PageController, :search_nested_results)
    get("/search/profile/a", PageController, :profile_version_a)
    get("/search/profile/b", PageController, :profile_version_b)
    get("/search/profile/results", PageController, :profile_results)
    get("/controls", PageController, :controls_form)
    get("/controls/result", PageController, :controls_result)
    get("/browser/extensions", PageController, :browser_extensions)
    get("/browser/popup/auto", PageController, :popup_auto)
    get("/browser/popup/click", PageController, :popup_click)
    get("/browser/popup/destination", PageController, :popup_destination)
    get("/session/user", PageController, :session_user)
    get("/session/user/:value", PageController, :set_session_user)
    get("/owner-form", PageController, :owner_form)
    get("/owner-form/result", PageController, :owner_form_result)
    get("/owner-form/redirect", PageController, :owner_form_redirect)
    get("/checkbox-array", PageController, :checkbox_array)
    get("/checkbox-array/result", PageController, :checkbox_array_result)
    get("/redirect/static", PageController, :redirect_static)
    get("/redirect/live", PageController, :redirect_live)
    get("/oracle/mismatch", PageController, :oracle_mismatch)
    get("/upload/static", PageController, :static_upload)

    live_session :fixtures,
      root_layout: {Cerberus.Fixtures.Layouts, :root},
      on_mount: Cerberus.Fixtures.LiveSandbox do
      live("/live/counter", CounterPageLive)
      live("/live/async_page", AsyncPageLive)
      live("/live/async_page_2", AsyncPage2Live)
      live("/live/sandbox/messages", SandboxMessagesLive)
      live("/live/redirects", RedirectsLive)
      live("/live/redirect-return", RedirectReturnLive)
      live("/live/form-change", FormChangeLive)
      live("/live/form-sync", FormSyncLive)
      live("/live/controls", SelectControlsLive)
      live("/live/checkbox-array", CheckboxArrayLive)
      live("/live/trigger-action", TriggerActionLive)
      live("/live/selector-edge", SelectorEdgeLive)
      live("/live/uploads", UploadLive)
      live("/live/nested", NestedLive)
      live("/live/oracle/mismatch", OracleMismatchLive)
    end
  end
end
