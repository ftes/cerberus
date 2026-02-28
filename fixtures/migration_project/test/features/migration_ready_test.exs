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
    |> assert_has_selector("h1")
    |> click_link("Counter")
    |> assert_has_selector("#count")
    |> click_button("Increment")
    |> assert_has_selector("#count")
  end

  defp assert_has_selector(session, selector) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.css(selector))
      _ -> PhoenixTest.Assertions.assert_has(session, selector)
    end
  end
end
