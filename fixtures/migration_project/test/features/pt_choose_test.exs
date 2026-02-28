defmodule MigrationFixtureWeb.PtChooseTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_choose", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/choose")
    |> choose_contact("Phone")
    |> submit_choice()
    |> assert_contact_choice("phone")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp choose_contact(session, label) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.choose(session, label)
      _ -> choose(session, label)
    end
  end

  defp assert_contact_choice(session, expected_value) do
    expected = "Contact via: #{expected_value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end

  defp submit_choice(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.submit(session, Cerberus.text("Apply Choice", exact: true))
      _ -> PhoenixTest.submit(session)
    end
  end
end
