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

  test "screenshot defaults to a temp PNG path" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot()

    assert session.current_path == "/articles"
  end

  @tag :tmp_dir
  test "screenshot captures browser PNG output to a requested path", %{tmp_dir: tmp_dir} do
    # NOTE: ExUnit :tmp_dir paths are deterministic for module+test. If multiple
    # mix test processes execute this same test in one checkout concurrently,
    # one process can remove this directory while another still reads artifacts.
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
