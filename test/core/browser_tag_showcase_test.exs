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
end
