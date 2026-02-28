defmodule Cerberus.CoreStaticUploadBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag :static
  @tag :live
  test "upload submits file inputs on static routes in phoenix mode", context do
    jpg = upload_fixture_path("elixir.jpg")

    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/upload/static")
        |> within("#static-upload-form", fn scoped ->
          scoped
          |> upload("Avatar", jpg)
          |> submit(text: "Upload Avatar", exact: true)
        end)
        |> assert_has(text("Uploaded file: elixir.jpg", exact: true))
      end
    )
  end

  defp upload_fixture_path(file_name) do
    Path.expand("../support/files/#{file_name}", __DIR__)
  end
end
