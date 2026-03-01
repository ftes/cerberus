defmodule Cerberus.Driver.Browser.ConfigTest do
  use ExUnit.Case, async: false

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Browser.AssertionHelpers
  alias Cerberus.Driver.Browser.PopupHelpers

  setup do
    browser_config = Application.get_env(:cerberus, :browser, [])

    on_exit(fn ->
      Application.put_env(:cerberus, :browser, browser_config)
    end)

    :ok
  end

  describe "browser_context_defaults/1" do
    test "loads viewport, user-agent, and init scripts from browser config" do
      Application.put_env(:cerberus, :browser,
        viewport: [width: 1280, height: 720],
        user_agent: "cerberus-test-agent",
        init_script: "window.fromSingle = true;",
        init_scripts: ["window.fromList = true;"]
      )

      assert %{
               viewport: %{width: 1280, height: 720},
               user_agent: "cerberus-test-agent",
               popup_mode: :allow,
               init_scripts: init_scripts
             } = Browser.browser_context_defaults([])

      assert init_scripts == [AssertionHelpers.preload_script(), "window.fromList = true;", "window.fromSingle = true;"]
    end

    test "session :browser opts override global browser config" do
      Application.put_env(:cerberus, :browser,
        viewport: [width: 800, height: 600],
        user_agent: "global-agent",
        init_scripts: ["window.fromGlobal = true;"]
      )

      assert %{
               viewport: %{width: 1024, height: 768},
               user_agent: "session-agent",
               popup_mode: :allow,
               init_scripts: init_scripts
             } =
               Browser.browser_context_defaults(
                 browser: [
                   viewport: {1024, 768},
                   user_agent: "session-agent",
                   init_scripts: ["window.fromSession = true;"]
                 ]
               )

      assert init_scripts == [AssertionHelpers.preload_script(), "window.fromSession = true;"]
    end

    test "adds same-tab popup preload script when popup_mode is :same_tab" do
      assert %{
               popup_mode: :same_tab,
               init_scripts: init_scripts
             } = Browser.browser_context_defaults(browser: [popup_mode: :same_tab])

      assert init_scripts == [AssertionHelpers.preload_script(), PopupHelpers.same_tab_popup_preload_script()]
    end

    test "raises on invalid popup mode" do
      assert_raise ArgumentError, ~r/:popup_mode must be :allow or :same_tab/, fn ->
        Browser.browser_context_defaults(browser: [popup_mode: :current_tab])
      end
    end

    test "raises on invalid viewport dimensions" do
      assert_raise ArgumentError, ~r/:viewport dimensions must be positive integers/, fn ->
        Browser.browser_context_defaults(browser: [viewport: [width: 0, height: 720]])
      end
    end
  end
end
