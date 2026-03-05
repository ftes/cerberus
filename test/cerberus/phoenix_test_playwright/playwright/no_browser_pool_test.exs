defmodule Cerberus.PhoenixTestPlaywright.Playwright.NoBrowserPoolTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "launches browser session for playwright fixture pages" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
  end

  @tag skip: "browser pool checkout internals are not part of Cerberus public API"
  test "launches new browser instead of checking out from pool" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
  end
end
