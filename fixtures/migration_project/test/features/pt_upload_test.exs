defmodule MigrationFixtureWeb.PtUploadTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_upload", %{conn: conn} do
    conn
    |> visit("/upload")
    |> within("#upload-form", fn scoped ->
      scoped
      |> upload_avatar(upload_fixture_path("avatar.jpg"))
      |> submit_upload()
    end)
    |> assert_uploaded_file("avatar.jpg")
  end

  defp upload_avatar(session, path) do
    upload(session, "Avatar", path)
  end

  defp submit_upload(session) do
    click_button(session, "Upload Avatar")
  end

  defp assert_uploaded_file(session, file_name) do
    expected = "Uploaded file: #{file_name}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end

  defp upload_fixture_path(file_name) do
    "test/support/files/#{file_name}"
  end
end
