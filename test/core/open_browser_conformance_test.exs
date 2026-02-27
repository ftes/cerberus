defmodule Cerberus.CoreOpenBrowserConformanceTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance

  @tag drivers: [:static, :browser]
  test "open_browser snapshots static pages consistently in static and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/articles")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Articles"
        File.rm(path)
      end)
    end)
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "open_browser snapshots live pages consistently in live and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/counter")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Count: 0"
        File.rm(path)
      end)
    end)
  end
end
