defmodule Cerberus.WithinClosestBehaviorTest do
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
    test "scoped assert_has/refute_has support closest with nested has filters (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/field-wrapper-errors")
      |> assert_has(has(closest(css(".fieldset"), from: label("Email")), text("can't be blank")))
      |> assert_has(has_not(closest(css(".fieldset"), from: label("Email")), text("Outer wrapper error")))
    end

    test "scoped click supports closest scope locator (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> within(closest(css("section"), from: text("Secondary Panel", exact: true)), &click(&1, link("Open")))
      |> assert_path("/search")
    end

    test "within supports has label filters for Phoenix-style field wrappers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/field-wrapper-errors")
      |> within(".fieldset" |> css() |> has(label("Name", exact: true)), fn scoped ->
        scoped
        |> assert_has(text("Name can't be blank", exact: true))
        |> refute_has(text("Email can't be blank", exact: true))
      end)
    end

    test "within closest picks only nearest nested field wrapper from label locator (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/field-wrapper-errors")
      |> within(
        closest(css(".fieldset"), from: label("Email", exact: true)),
        &(&1
          |> assert_has(text("Email can't be blank", exact: true))
          |> refute_has(text("Outer wrapper error", exact: true)))
      )
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
