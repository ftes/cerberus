defmodule Cerberus.BrowserTagShowcaseTest do
  use ExUnit.Case, async: true

  import Cerberus

  setup_all do
    {:ok, browser_session: session(:browser)}
  end

  test "browser session uses default browser lane", %{browser_session: session} do
    assert session.__struct__ == Cerberus.Driver.Browser

    session
    |> visit("/articles")
    |> assert_has(text("Articles", exact: true))
  end
end
