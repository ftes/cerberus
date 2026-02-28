defmodule MigrationFixtureWeb.PtUploadTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_upload", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/upload")
    |> within("#upload-form", fn scoped ->
      scoped
      |> upload_avatar(upload_fixture_path("avatar.jpg"))
      |> submit_upload()
    end)
    |> assert_uploaded_file("avatar.jpg")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp upload_avatar(session, path) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.upload(session, "Avatar", path)
      _ -> upload(session, "Avatar", path)
    end
  end

  defp submit_upload(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.submit(session, Cerberus.text("Upload Avatar", exact: true))
      _ -> PhoenixTest.submit(session)
    end
  end

  defp assert_uploaded_file(session, file_name) do
    expected = "Uploaded file: #{file_name}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end

  defp upload_fixture_path(file_name) do
    Path.expand("../support/files/#{file_name}", __DIR__)
  end
end
