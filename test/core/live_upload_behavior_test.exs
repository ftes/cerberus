defmodule Cerberus.CoreLiveUploadBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag :live
  test "upload keeps active form unset and raises translated upload errors", context do
    jpg = upload_fixture_path("elixir.jpg")
    png = upload_fixture_path("phoenix.png")

    Harness.run!(
      context,
      fn session ->
        session =
          session
          |> visit("/live/uploads")
          |> within("#upload-change-form", fn scoped ->
            upload(scoped, "Avatar", jpg)
          end)

        assert %{active_form: nil} = session.form_data

        assert_raise ExUnit.AssertionError, ~r/Unsupported file type/, fn ->
          session
          |> visit("/live/uploads")
          |> within("#full-form", fn scoped ->
            upload(scoped, "Avatar", png)
          end)
        end

        assert_raise ExUnit.AssertionError, ~r/Too many files uploaded/, fn ->
          session
          |> visit("/live/uploads")
          |> within("#full-form", fn scoped ->
            scoped
            |> upload("Avatar", jpg)
            |> upload("Avatar", jpg)
          end)
        end

        assert_raise ExUnit.AssertionError, ~r/File too large/, fn ->
          session
          |> visit("/live/uploads")
          |> within("#tiny-upload-form", fn scoped ->
            upload(scoped, "Tiny", jpg)
          end)
        end

        session
      end
    )
  end

  @tag :live
  @tag :browser
  test "upload triggers phx-change validations on file selection", context do
    jpg = upload_fixture_path("elixir.jpg")

    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/uploads")
        |> within("#upload-change-form", fn scoped ->
          upload(scoped, "Avatar", jpg)
        end)
        |> assert_has(text("phx-change triggered on file selection", exact: true))
      end
    )
  end

  @tag :live
  @tag :browser
  test "upload follows redirects from progress callbacks", context do
    jpg = upload_fixture_path("elixir.jpg")

    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/uploads")
        |> within("#upload-redirect-form", fn scoped ->
          upload(scoped, "Redirect Avatar", jpg)
        end)
        |> assert_path("/live/async_page_2")
      end
    )
  end

  defp upload_fixture_path(file_name) do
    Path.expand("../support/files/#{file_name}", __DIR__)
  end
end
