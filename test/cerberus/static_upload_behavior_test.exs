defmodule Cerberus.StaticUploadBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "upload and submit support testid locators on static routes in phoenix mode" do
    jpg = upload_fixture_path("elixir.jpg")

    :phoenix
    |> session()
    |> visit("/upload/static")
    |> within(css("#static-upload-form"), fn scoped ->
      scoped
      |> upload(testid("static-avatar-upload"), jpg)
      |> submit(testid("static-upload-submit"))
    end)
    |> assert_has(text("Uploaded file: elixir.jpg", exact: true))
  end

  defp upload_fixture_path(file_name) do
    "test/support/files/#{file_name}"
  end
end
