defmodule MigrationFixtureWeb.PtMultiUserTabTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_multi_user_tab", %{conn: conn} do
    primary =
      conn
      |> session_for_mode()
      |> visit("/session-counter")
      |> assert_session_count("0")
      |> click_link("Increment Session")
      |> assert_session_count("1")

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" ->
        same_user_tab =
          primary
          |> Cerberus.open_tab()
          |> Cerberus.visit("/session-counter")
          |> assert_session_count("1")

        _same_user_tab_closed = Cerberus.close_tab(same_user_tab)

        isolated_user =
          primary
          |> Cerberus.open_user()
          |> Cerberus.visit("/session-counter")
          |> assert_session_count("0")

        _isolated_user_closed = Cerberus.close_tab(isolated_user)

      _ ->
        :ok
    end
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_session_count(session, value) do
    expected = "Session Count: #{value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end
end
