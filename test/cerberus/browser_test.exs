defmodule Cerberus.BrowserTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  test "screenshot rejects invalid options" do
    assert_raise ArgumentError, ~r/:path must be a non-empty string path/, fn ->
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot(path: "")
    end
  end

  test "screenshot defaults to a temp PNG path and records it in last_result" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot()

    assert %{op: :screenshot, observed: %{path: path, full_page: false}} = session.last_result
    assert File.exists?(path)
    assert String.ends_with?(path, ".png")
    File.rm(path)
  end

  @tag :tmp_dir
  test "screenshot captures browser PNG output to a requested path", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "cerberus-screenshot.png")

    session =
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot(path)

    assert session.current_path == "/articles"
    assert File.exists?(path)

    png = File.read!(path)
    assert byte_size(png) > 0
    assert :binary.part(png, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
    File.rm(path)
  end
end
