defmodule CerberusTest.BrowserTagShowcaseTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "browser session uses default browser lane" do
    session = session(:browser)

    assert session.__struct__ == Cerberus.Driver.Browser

    session
    |> visit("/articles")
    |> assert_has(text("Articles", exact: true))
  end
end
