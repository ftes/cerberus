defmodule MigrationFixtureWeb.PtpwScreenshotTest do
  use PhoenixTest.Playwright.Case, async: true

  @playwright_package "assets/node_modules/playwright/package.json"

  if not File.exists?(@playwright_package) do
    @moduletag skip: "Install Playwright with npm --prefix assets install playwright."
  end

  test "ptpw_screenshot captures a browser screenshot", %{conn: conn} do
    screenshot_path =
      Path.join(
        System.tmp_dir!(),
        "cerberus-migration-ptpw-screenshot-#{System.unique_integer([:positive])}.png"
      )

    try do
      conn
      |> visit("/")
      |> screenshot(screenshot_path)

      assert File.exists?(screenshot_path)
    after
      File.rm(screenshot_path)
    end
  end
end
