defmodule MigrationFixtureWeb.MigrationReadyTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  defp feature_session(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  test "single flow can run pre and post migration", %{conn: conn} do
    conn
    |> feature_session()
    |> visit("/")
    |> assert_title("Migration fixture")
    |> click_link("Counter")
    |> assert_count("0")
    |> click_button("Increment")
    |> assert_count("1")
  end

  defp assert_title(session, expected_text) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected_text, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "h1", text: expected_text)
    end
  end

  defp assert_count(session, expected_text) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected_text, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "#count", text: expected_text)
    end
  end
end
