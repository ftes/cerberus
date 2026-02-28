defmodule Cerberus.Driver.Browser.ConfigTest do
  use ExUnit.Case, async: false

  alias Cerberus.Driver.Browser

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
               init_scripts: ["window.fromList = true;", "window.fromSingle = true;"]
             } = Browser.browser_context_defaults([])
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
               init_scripts: ["window.fromSession = true;"]
             } =
               Browser.browser_context_defaults(
                 browser: [
                   viewport: {1024, 768},
                   user_agent: "session-agent",
                   init_scripts: ["window.fromSession = true;"]
                 ]
               )
    end

    test "raises on invalid viewport dimensions" do
      assert_raise ArgumentError, ~r/:viewport dimensions must be positive integers/, fn ->
        Browser.browser_context_defaults(browser: [viewport: [width: 0, height: 720]])
      end
    end
  end
end
