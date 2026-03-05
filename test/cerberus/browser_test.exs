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

  @tag :tmp_dir
  test "screenshot supports callback, return_result, and open options", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "cerberus-screenshot-options.png")

    previous_open_fun = Application.get_env(:cerberus, :open_with_system_cmd)

    Application.put_env(:cerberus, :open_with_system_cmd, fn opened_path ->
      send(self(), {:opened_screenshot, opened_path})
      :ok
    end)

    on_exit(fn ->
      if is_nil(previous_open_fun) do
        Application.delete_env(:cerberus, :open_with_system_cmd)
      else
        Application.put_env(:cerberus, :open_with_system_cmd, previous_open_fun)
      end
    end)

    session =
      :browser
      |> session()
      |> visit("/articles")

    assert screenshot(session, [path: path], fn png_binary ->
             assert is_binary(png_binary)
             assert byte_size(png_binary) > 0
             assert :binary.part(png_binary, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
           end) == session

    png_binary = screenshot(session, path: path, return_result: true, open: true)

    assert is_binary(png_binary)
    assert byte_size(png_binary) > 0
    assert :binary.part(png_binary, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
    assert_receive {:opened_screenshot, ^path}
  end
end
