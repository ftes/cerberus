defmodule Cerberus.OpenBrowserBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "open_browser snapshots static pages consistently in static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Articles"
        File.rm(path)
      end)
    end

    test "open_browser snapshots live pages consistently in live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Count: 0"
        File.rm(path)
      end)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
