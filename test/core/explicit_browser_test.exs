defmodule Cerberus.CoreExplicitBrowserTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag browser: true
  @moduletag explicit_browser: true
  @moduletag drivers: [:chrome, :firefox]

  test "module-level explicit drivers run both browser lanes", context do
    results =
      Harness.run!(context, fn session ->
        session =
          session
          |> visit("/articles")
          |> assert_has(text("Articles", exact: true))

        %{browser_name: session.browser_name}
      end)

    assert Enum.map(results, & &1.driver) == [:chrome, :firefox]

    browser_names_by_driver = Map.new(results, fn result -> {result.driver, result.value.browser_name} end)

    assert browser_names_by_driver == %{chrome: :chrome, firefox: :firefox}
  end

  @tag drivers: [:firefox]
  test "test-level explicit drivers can force firefox only", context do
    results =
      Harness.run!(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))
      end)

    assert Enum.map(results, & &1.driver) == [:firefox]
  end

  test "explicit chrome/firefox drivers map to the matching runtime browser", context do
    results =
      Harness.run!(context, fn session ->
        %{user_agent: Cerberus.Browser.evaluate_js(session, "navigator.userAgent")}
      end)

    user_agents_by_driver = Map.new(results, fn result -> {result.driver, result.value.user_agent} end)

    assert user_agents_by_driver[:chrome] =~ "Chrome"
    assert user_agents_by_driver[:firefox] =~ "Firefox"
  end
end
