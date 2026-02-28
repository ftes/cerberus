defmodule MigrationFixtureWeb.PtLiveNavTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_live_nav", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/live-nav")
    |> assert_step("0")
    |> click_link("Patch Step 1")
    |> assert_step("1")
    |> click_link("Navigate Counter")
    |> assert_counter_path()
    |> assert_count("0")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_step(session, value) do
    expected = "Step: #{value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "#step", text: expected)
    end
  end

  defp assert_counter_path(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_path(session, "/counter")
      _ -> PhoenixTest.assert_path(session, "/counter")
    end
  end

  defp assert_count(session, value) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(value, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "#count", text: value)
    end
  end
end
