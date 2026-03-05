defmodule Cerberus.PhoenixTestPlaywright.FixtureSmokeTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "prefixed static and live fixtures are reachable on phoenix driver" do
    :phoenix
    |> session()
    |> visit("/phoenix_test/playwright/page/index")
    |> assert_has(text("Main page", exact: true))
    |> visit("/phoenix_test/playwright/live/index")
    |> assert_has(text("LiveView main page", exact: true))
  end

  test "prefixed playwright fixture is reachable on browser driver" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
  end
end
