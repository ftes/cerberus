defmodule Cerberus.BrowserTagShowcaseTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.BrowserSessions

  setup_all do
    {:ok, browser_session: BrowserSessions.session!()}
  end

  test "browser session uses default browser lane", %{browser_session: session} do
    assert session.__struct__ == Cerberus.Driver.Browser

    session
    |> visit("/articles")
    |> assert_has(text("Articles", exact: true))
  end
end
