defmodule Cerberus.Fixtures.Router do
  @moduledoc false
  use Phoenix.Router

  import Phoenix.LiveView.Router

  alias Cerberus.Fixtures.LiveSandbox
  alias Cerberus.Fixtures.PhoenixTest.LayoutView, as: PhoenixTestLayoutView
  alias Cerberus.Fixtures.PhoenixTestPlaywright
  alias Cerberus.Fixtures.PhoenixTestPlaywright.LayoutView, as: PhoenixTestPlaywrightLayoutView

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

  pipeline :phoenix_test_browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {PhoenixTestLayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :phoenix_test_playwright_browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {PhoenixTestPlaywrightLayoutView, :root})
    plug(:put_secure_browser_headers)
  end

  pipeline :phoenix_test_playwright_browser_csrf do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {PhoenixTestPlaywrightLayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :phoenix_test_auth_header do
    plug(:phoenix_test_proxy_header_auth)
  end

  scope "/phoenix_test", Cerberus.Fixtures.PhoenixTest do
    pipe_through(:phoenix_test_browser)

    post("/page/create_record", PageController, :create)
    post("/page/update_record", PageController, :update)
    put("/page/update_record", PageController, :update)
    post("/page/delete_record", PageController, :delete)
    delete("/page/delete_record", PageController, :delete)
    get("/page/unauthorized", PageController, :unauthorized)
    get("/page/redirect_to_static", PageController, :redirect_to_static)
    post("/page/redirect_to_liveview", PageController, :redirect_to_liveview)
    post("/page/redirect_to_static", PageController, :redirect_to_static)
    get("/page/:page", PageController, :show)

    live_session :phoenix_test_live_pages, layout: {PhoenixTestLayoutView, :app} do
      live("/live/index", IndexLive)
      live("/live/index/alias", IndexLive)
      live("/live/page_2", Page2Live)
      live("/live/async_page", AsyncPageLive)
      live("/live/async_page_2", AsyncPage2Live)
      live("/live/dynamic_form", DynamicFormLive)
      live("/live/simple_ordinal_inputs", SimpleOrdinalInputsLive)
      live("/live/nested", NestedLive)
    end

    scope "/auth" do
      pipe_through([:phoenix_test_auth_header])

      live_session :phoenix_test_auth, layout: {PhoenixTestLayoutView, :app} do
        live("/live/index", IndexLive)
        live("/live/page_2", Page2Live)
      end
    end

    live("/live/redirect_on_mount/:redirect_type", RedirectLive)
  end

  scope "/phoenix_test/playwright/pw", Cerberus.Fixtures.PhoenixTestPlaywright.Playwright do
    pipe_through([:phoenix_test_playwright_browser_csrf])

    live_session :phoenix_test_playwright_pw, on_mount: LiveSandbox do
      live("/live", Live)
      live("/live/ecto", EctoLive)
    end

    get("/other", PageController, :other)
    get("/longer-than-viewport", PageController, :longer_than_viewport)
    get("/cookies", PageController, :cookies)
    get("/session", PageController, :session)
    get("/headers", PageController, :headers)
    get("/js-script-console-error", PageController, :js_script_console_error)
  end

  scope "/phoenix_test/playwright", PhoenixTestPlaywright do
    pipe_through(:phoenix_test_playwright_browser)

    post("/page/create_record", PageController, :create)
    put("/page/update_record", PageController, :update)
    delete("/page/delete_record", PageController, :delete)
    get("/page/unauthorized", PageController, :unauthorized)
    get("/page/redirect_to_static", PageController, :redirect_to_static)
    post("/page/redirect_to_liveview", PageController, :redirect_to_liveview)
    post("/page/redirect_to_static", PageController, :redirect_to_static)
    get("/page/:page", PageController, :show)
  end

  scope "/phoenix_test/playwright", PhoenixTestPlaywright do
    pipe_through(:phoenix_test_playwright_browser_csrf)

    live_session :phoenix_test_playwright_live_pages,
      layout: {PhoenixTestPlaywrightLayoutView, :app},
      on_mount: LiveSandbox do
      live("/live/index", IndexLive)
      live("/live/index/alias", IndexLive)
      live("/live/page_2", Page2Live)
      live("/live/async_page", AsyncPageLive)
      live("/live/async_page_2", AsyncPage2Live)
      live("/live/dynamic_form", DynamicFormLive)
      live("/live/simple_ordinal_inputs", SimpleOrdinalInputsLive)
      live("/live/nested", NestedLive)
    end

    scope "/auth" do
      pipe_through([:phoenix_test_auth_header])

      live_session :phoenix_test_playwright_auth,
        layout: {PhoenixTestPlaywrightLayoutView, :app},
        on_mount: LiveSandbox do
        live("/live/index", IndexLive)
        live("/live/page_2", Page2Live)
      end
    end

    live("/live/redirect_on_mount/:redirect_type", RedirectLive)
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
    get("/styled-snapshot", PageController, :styled_snapshot)
    get("/main", PageController, :main)
    get("/sandbox/messages", PageController, :sandbox_messages)
    get("/scoped", PageController, :scoped)
    get("/field-wrapper-errors", PageController, :field_wrapper_errors)
    get("/search", PageController, :search_form)
    get("/search/results", PageController, :search_results)
    get("/search/nested/results", PageController, :search_nested_results)
    get("/nested-submit", PageController, :nested_submit_form)
    post("/nested-submit/result", PageController, :nested_submit_result)
    get("/search/profile/a", PageController, :profile_version_a)
    get("/search/profile/b", PageController, :profile_version_b)
    get("/search/profile/results", PageController, :profile_results)
    get("/controls", PageController, :controls_form)
    get("/controls/result", PageController, :controls_result)
    get("/browser/extensions", PageController, :browser_extensions)
    get("/browser/download/report", PageController, :browser_download_report)
    get("/browser/link/semantics", PageController, :browser_link_semantics)
    get("/browser/readiness/disconnected-live-root", PageController, :disconnected_live_root)
    get("/browser/readiness/busy-live-root", PageController, :busy_live_root)
    get("/browser/readiness/mixed-live-roots", PageController, :mixed_live_roots)
    get("/browser/readiness/source", PageController, :mixed_live_roots_source)
    get("/browser/popup/auto", PageController, :popup_auto)
    get("/browser/popup/click", PageController, :popup_click)
    get("/browser/popup/destination", PageController, :popup_destination)
    get("/browser/iframe/cross-origin", PageController, :iframe_cross_origin)
    get("/browser/iframe/same-origin", PageController, :iframe_same_origin)
    get("/browser/iframe/same-origin-target", PageController, :iframe_same_origin_target)
    get("/browser/iframe/target", PageController, :iframe_target)
    get("/auth/static/users/register", AuthController, :static_register)
    get("/auth/static/users/log_in", AuthController, :static_log_in)
    get("/auth/static/dashboard", AuthController, :static_dashboard)
    post("/auth/users/register", AuthController, :register)
    post("/auth/users/log_in", AuthController, :log_in)
    post("/auth/users/log_out", AuthController, :log_out)
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
      on_mount: LiveSandbox do
      live("/live/counter", CounterPageLive)
      live("/live/async_page", AsyncPageLive)
      live("/live/async_page_2", AsyncPage2Live)
      live("/live/sandbox/messages", SandboxMessagesLive)
      live("/live/redirects", RedirectsLive)
      live("/live/redirect-return", RedirectReturnLive)
      live("/live/form-change", FormChangeLive)
      live("/live/form-sync", FormSyncLive)
      live("/live/controls", SelectControlsLive)
      live("/live/actionability/delayed", DelayedActionabilityLive)
      live("/live/checkbox-array", CheckboxArrayLive)
      live("/live/trigger-action", TriggerActionLive)
      live("/live/selector-edge", SelectorEdgeLive)
      live("/live/uploads", UploadLive)
      live("/live/nested", NestedLive)
      live("/live/oracle/mismatch", OracleMismatchLive)
      live("/auth/live/users/register", AuthRegisterLive)
      live("/auth/live/users/log_in", AuthLogInLive)
      live("/auth/live/dashboard", AuthDashboardLive)
    end
  end

  defp phoenix_test_proxy_header_auth(conn, _opts) do
    Cerberus.Fixtures.PhoenixTest.Router.proxy_header_auth(conn, [])
  end
end
