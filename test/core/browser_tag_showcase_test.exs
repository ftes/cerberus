defmodule Cerberus.CoreBrowserTagShowcaseTest do
  use ExUnit.Case, async: true

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
end
