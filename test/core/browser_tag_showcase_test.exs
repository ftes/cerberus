defmodule Cerberus.CoreBrowserTagShowcaseTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag browser: true
  @moduletag drivers: [:browser]

  test "module-level drivers tag uses default browser lane", context do
    results =
      Harness.run!(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))
      end)

    assert Enum.map(results, & &1.driver) == [:browser]
  end

  describe "describe-level browser override" do
    @describetag drivers: [:firefox]

    test "describe tag can force firefox only", context do
      results =
        Harness.run!(context, fn session ->
          session
          |> visit("/articles")
          |> assert_has(text("Articles", exact: true))
        end)

      assert Enum.map(results, & &1.driver) == [:firefox]
    end
  end

  @tag drivers: [:chrome, :firefox]
  test "test-level drivers tag can run both browsers in one test", context do
    results =
      Harness.run!(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))
      end)

    assert Enum.map(results, & &1.driver) == [:chrome, :firefox]
  end

  @tag drivers: [:chrome, :firefox]
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
