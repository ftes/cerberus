defmodule Cerberus.CoreBrowserTagShowcaseTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :browser

  test "module-level browser tag uses default browser lane", context do
    results =
      Harness.run!(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))
      end)

    assert Enum.map(results, & &1.driver) == [:browser]
  end
end
