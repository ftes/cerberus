defmodule PhoenixTest.LiveTestFixture do
  @moduledoc false
  use ExUnit.Case, async: true

  import PhoenixTest

  alias PhoenixTest.Driver

  test "sample live flow", %{conn: conn} do
    conn
    |> visit("/live/index")
    |> click_button("Change page title")
    |> then(fn session ->
      Driver.render_page_title(session)
    end)
  end
end
