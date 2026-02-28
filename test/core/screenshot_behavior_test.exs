defmodule Cerberus.CoreScreenshotBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness
  alias ExUnit.AssertionError

  @moduletag :conformance

  @tag drivers: [:static, :live]
  test "screenshot is explicit unsupported for static/live drivers", context do
    Harness.run!(context, fn session ->
      session = visit(session, "/articles")

      error =
        assert_raise AssertionError, fn ->
          screenshot(session, path: "tmp/ignored.png")
        end

      assert error.message =~ "screenshot is not implemented"
      session
    end)
  end

  @tag browser: true
  @tag :tmp_dir
  @tag drivers: [:browser]
  test "screenshot emits PNG output in browser driver", %{tmp_dir: tmp_dir} = context do
    Harness.run!(context, fn session ->
      session = visit(session, "/articles")

      path = Path.join(tmp_dir, "cerberus-screenshot.png")

      session = screenshot(session, path: path)
      assert File.exists?(path)

      png = File.read!(path)
      assert :binary.part(png, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
      File.rm(path)
      session
    end)
  end
end
