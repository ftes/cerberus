defmodule Cerberus.PhoenixTestPlaywright.Playwright.EctoSandboxTest do
  use ExUnit.Case, async: true

  import Cerberus

  setup context do
    stop_owner_delay = context[:ecto_sandbox_stop_owner_delay] || 0

    on_exit(fn ->
      if stop_owner_delay > 0, do: Process.sleep(stop_owner_delay)
    end)

    metadata_header = sql_sandbox_user_agent(Cerberus.Fixtures.Repo, context)

    browser = session(:browser, user_agent: metadata_header)

    {:ok, conn: browser}
  end

  for delay_ms <- [0, 100] do
    @delay_ms delay_ms

    describe "delay: #{delay_ms}ms does not require ecto_sandbox_stop_owner_delay" do
      setup %{conn: conn} do
        [conn: conn |> visit("/phoenix_test/playwright/pw/live/ecto?delay_ms=#{@delay_ms}") |> await_ecto_live_results()]
      end

      test "shows version", %{conn: conn} do
        assert_loaded(conn, "Version: PostgreSQL", exact: false)
      end

      test "shows long running query result", %{conn: conn} do
        assert_loaded(conn, "Long running: void")
      end

      test "shows delayed version", %{conn: conn} do
        assert_loaded(conn, "Delayed version: PostgreSQL", exact: false)
      end
    end
  end

  defp assert_loaded(session, text_value, opts \\ []) do
    exact? = Keyword.get(opts, :exact, true)
    assert_has(session, text(text_value, exact: exact?), timeout: 5_000)
  end

  defp await_ecto_live_results(session) do
    session
    |> assert_loaded("Version: PostgreSQL", exact: false)
    |> assert_loaded("Long running: void")
    |> assert_loaded("Delayed version: PostgreSQL", exact: false)
  end
end
