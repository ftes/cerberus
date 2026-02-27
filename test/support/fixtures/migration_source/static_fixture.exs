defmodule PhoenixTest.StaticTestFixture do
  @moduledoc false
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.TestHelpers

  alias PhoenixTest.Assertions

  test "sample static flow", %{conn: conn} do
    conn
    |> visit("/page/index")
    |> click_link("Page 2")
    |> Assertions.assert_has("h1", text: "Page 2")
  end
end
