defmodule Cerberus.PhoenixTestPlaywright.Playwright.CaseTest do
  use ExUnit.Case, async: true

  import Cerberus

  @tag :screenshot
  test "screenshot tag flow can run browser integration" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
  end

  @tag :trace
  test "trace tag flow can run browser integration" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
  end

  @tag skip: "browser locale override parity not exposed as a Cerberus public session option"
  test "override locale via setup" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/headers")
    |> assert_has(text("accept-language: de", exact: false))
  end
end
