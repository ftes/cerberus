defmodule Cerberus.PathScopeBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  @shared_browser_session_boot_timeout_ms 30_000
  @shared_browser_session_stop_timeout_ms 5_000

  setup_all do
    {owner_pid, browser_session} = start_shared_browser_session!()

    on_exit(fn ->
      stop_shared_browser_session(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "within scopes static operations and assertions across static and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> within(css("#secondary-panel"), fn scoped ->
        scoped
        |> assert_has(text("Secondary Panel", exact: true))
        |> assert_has(text("Status: secondary", exact: true))
        |> refute_has(text("Status: primary", exact: true))
        |> click(link("Open"))
      end)
      |> assert_path("/search")
      |> assert_has(text("Search", exact: true))
    end

    test "path assertions with query options are consistent in static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(label("Search term"), "phoenix")
      |> submit(button("Run Search"))
      |> assert_path("/search/results", query: %{q: "phoenix"})
      |> refute_path("/search/results", query: %{q: "elixir"})
    end

    test "within scopes live duplicate button clicks consistently in live and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> within(css("#secondary-actions"), fn scoped ->
        click(scoped, button("Apply"))
      end)
      |> within(css("#selected-result"), fn scoped ->
        scoped
        |> assert_has(text("Selected: secondary", exact: true))
        |> refute_has(text("Selected: primary", exact: true))
      end)
    end

    test "path assertions track live patch query transitions across drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/redirects")
      |> click(button("Patch link"))
      |> assert_path("/live/redirects", query: [details: "true", foo: "bar"])
      |> assert_path("/live/redirects?details=true&foo=bar")
      |> refute_path("/live/counter")
    end

    test "within accepts locator inputs across static and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> within(css("#secondary-panel"), fn scoped ->
        scoped
        |> assert_has(text("Secondary Panel", exact: true))
        |> click(link("Open"))
      end)
      |> assert_path("/search")
      |> assert_has(text("Search", exact: true))
    end

    test "scoped assert_has/refute_has accept explicit text and regex locators (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> assert_has(css("#secondary-panel"), text("Status: secondary"))
      |> assert_has(css("#secondary-panel"), text(~r/Status:\s+secondary/))
      |> refute_has(css("#secondary-panel"), text("Status: primary"))
    end
  end

  defp driver_session(:phoenix, _context), do: session(:phoenix)
  defp driver_session(:browser, context), do: context.shared_browser_session

  defp start_shared_browser_session! do
    parent = self()

    owner_pid =
      spawn_link(fn ->
        try do
          browser_session = session(:browser)
          send(parent, {:shared_browser_session_ready, self(), browser_session})

          receive do
            :stop -> :ok
          end
        rescue
          error ->
            send(parent, {:shared_browser_session_failed, self(), error, __STACKTRACE__})
        end
      end)

    receive do
      {:shared_browser_session_ready, ^owner_pid, browser_session} ->
        {owner_pid, browser_session}

      {:shared_browser_session_failed, ^owner_pid, error, stacktrace} ->
        reraise(error, stacktrace)
    after
      @shared_browser_session_boot_timeout_ms ->
        Process.exit(owner_pid, :kill)

        raise "timed out starting shared browser session after #{@shared_browser_session_boot_timeout_ms}ms"
    end
  end

  defp stop_shared_browser_session(owner_pid) when is_pid(owner_pid) do
    if Process.alive?(owner_pid) do
      ref = Process.monitor(owner_pid)
      send(owner_pid, :stop)

      receive do
        {:DOWN, ^ref, :process, ^owner_pid, _reason} -> :ok
      after
        @shared_browser_session_stop_timeout_ms ->
          Process.exit(owner_pid, :kill)
      end
    end

    :ok
  end
end
