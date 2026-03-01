defmodule CerberusTest.StaticUploadBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "upload submits file inputs on static routes in phoenix mode" do
    jpg = upload_fixture_path("elixir.jpg")

    :phoenix
    |> session()
    |> visit("/upload/static")
    |> within("#static-upload-form", fn scoped ->
      scoped
      |> upload("Avatar", jpg)
      |> submit(text: "Upload Avatar", exact: true)
    end)
    |> assert_has(text("Uploaded file: elixir.jpg", exact: true))
  end

  defp upload_fixture_path(file_name) do
    "test/support/files/#{file_name}"
  end
end
