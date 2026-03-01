defmodule CerberusTest.OpenBrowserBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "open_browser snapshots static pages consistently in static and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Articles"
        File.rm(path)
      end)
    end

    test "open_browser snapshots live pages consistently in live and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/counter")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Count: 0"
        File.rm(path)
      end)
    end
  end
end
