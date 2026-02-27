defmodule Cerberus.CoreScreenshotConformanceTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Harness
  alias ExUnit.AssertionError

  @moduletag :conformance
  @moduletag drivers: [:static, :live, :browser]

  test "screenshot is browser-only and emits PNG output in browser driver", context do
    Harness.run!(context, fn session ->
      session = visit(session, "/articles")

      case session do
        %BrowserSession{} ->
          path =
            Path.join(
              System.tmp_dir!(),
              "cerberus-conformance-screenshot-#{System.unique_integer([:positive])}.png"
            )

          session = screenshot(session, path: path)
          assert File.exists?(path)

          png = File.read!(path)
          assert :binary.part(png, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
          File.rm(path)
          session

        _ ->
          error =
            assert_raise AssertionError, fn ->
              screenshot(session, path: "tmp/ignored.png")
            end

          assert error.message =~ "screenshot is not implemented"
          session
      end
    end)
  end
end
