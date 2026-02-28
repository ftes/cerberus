defmodule MigrationFixtureWeb.PhoenixTestPlaywrightBaselineTest do
  use PhoenixTest.Playwright.Case, async: true

  @playwright_package Path.expand("../../assets/node_modules/playwright/package.json", __DIR__)

  if not File.exists?(@playwright_package) do
    @moduletag skip: "Install Playwright with npm --prefix assets install playwright."
  end

  setup_all do
    {:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
    :ok
  end

  test "phoenix_test_playwright browser flow", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("h1", text: "Migration fixture")
    |> click_link("Counter")
    |> assert_has("body .phx-connected")
    |> click_button("Increment")
    |> assert_has("#count", text: "1")
  end
end
