defmodule Cerberus.PhoenixTestPlaywright.PlaywrightTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  describe "screenshot" do
    @tag :tmp_dir
    test "takes a screenshot of the current page as a PNG", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "ptp-png.png")

      :browser
      |> session()
      |> visit("/phoenix_test/playwright/pw/longer-than-viewport")
      |> assert_has(text("Longer than viewport", exact: true))
      |> screenshot(path: path, full_page: false)

      assert File.exists?(path)
    end

    @tag :tmp_dir
    test "takes a screenshot of the current page as a JPEG", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "ptp-jpg.jpg")

      :browser
      |> session()
      |> visit("/phoenix_test/playwright/pw/longer-than-viewport")
      |> assert_has(text("Longer than viewport", exact: true))
      |> screenshot(path: path)

      assert File.exists?(path)
    end

    @tag :tmp_dir
    test "full page screenshots are larger in file size than non-full-page", %{tmp_dir: tmp_dir} do
      full_page_path = Path.join(tmp_dir, "ptp-full-page.png")
      viewport_path = Path.join(tmp_dir, "ptp-viewport.png")

      :browser
      |> session()
      |> visit("/phoenix_test/playwright/pw/longer-than-viewport")
      |> assert_has(text("Longer than viewport", exact: true))
      |> screenshot(path: full_page_path, full_page: true)
      |> screenshot(path: viewport_path, full_page: false)

      assert {:ok, %File.Stat{size: full_page_size}} = File.stat(full_page_path)
      assert {:ok, %File.Stat{size: viewport_size}} = File.stat(viewport_path)
      assert full_page_size > viewport_size
    end
  end

  test "open_browser callback receives rendered html path" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> open_browser(fn path ->
      html = path |> File.read!() |> LazyHTML.from_document()
      css_hrefs = html |> LazyHTML.query("link[rel=stylesheet]") |> LazyHTML.attribute("href")
      assert Enum.any?(css_hrefs, &String.contains?(&1, "/assets/app.css"))
      path
    end)
    |> assert_has(text("Playwright", exact: true))
  end

  describe "evaluate_js" do
    test "can modify the DOM" do
      :browser
      |> session()
      |> visit("/phoenix_test/playwright/pw/other")
      |> evaluate_js("document.querySelector('h1').textContent = 'Modified'")
      |> assert_has(text("Modified", exact: true))
    end

    test "passes result to callback when provided" do
      :browser
      |> session()
      |> visit("/phoenix_test/playwright/pw/other")
      |> evaluate_js("document.querySelector('h1').textContent", fn title ->
        send(self(), {:title, title})
      end)
      |> assert_has(text("Other", exact: true))

      assert_receive {:title, "Other"}
    end
  end

  test "fills and submits form via keyboard" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> type("My text", selector: "#text-input")
    |> assert_has(text("text: My text", exact: false))
    |> press("Enter", selector: "#text-input")
    |> assert_has(text("text: My text", exact: false))
  end

  test "drag triggers browser-side drop behavior" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> refute_has(text("dropped", exact: true))
    |> drag("#drag-source", "#drag-target")
    |> assert_has(text("dropped", exact: true))
  end

  test "add_cookie sets a plain cookie" do
    :browser
    |> session()
    |> add_cookie("name", "42")
    |> visit("/phoenix_test/playwright/pw/cookies")
    |> assert_has(text("name: 42", exact: false))
  end
end
