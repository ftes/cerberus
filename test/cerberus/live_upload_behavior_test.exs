defmodule Cerberus.LiveUploadBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "upload keeps active form unset and raises translated upload errors" do
    jpg = upload_fixture_path("elixir.jpg")
    png = upload_fixture_path("phoenix.png")

    session =
      :phoenix
      |> session()
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, "Avatar", jpg)
      end)

    assert %{active_form: nil} = session.form_data

    assert_raise ExUnit.AssertionError, ~r/Unsupported file type/, fn ->
      session
      |> visit("/live/uploads")
      |> within(css("#full-form"), fn scoped ->
        upload(scoped, "Avatar", png)
      end)
    end

    assert_raise ExUnit.AssertionError, ~r/Too many files uploaded/, fn ->
      session
      |> visit("/live/uploads")
      |> within(css("#full-form"), fn scoped ->
        scoped
        |> upload("Avatar", jpg)
        |> upload("Avatar", jpg)
      end)
    end

    assert_raise ExUnit.AssertionError, ~r/File too large/, fn ->
      session
      |> visit("/live/uploads")
      |> within(css("#tiny-upload-form"), fn scoped ->
        upload(scoped, "Tiny", jpg)
      end)
    end
  end

  for driver <- [:phoenix, :browser] do
    test "upload triggers phx-change validations on file selection (#{driver})" do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> session()
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, "Avatar", jpg)
      end)
      |> assert_has(text("phx-change triggered on file selection", exact: true))
    end

    test "upload supports testid locators on live file inputs (#{driver})" do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> session()
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, testid("live-upload-change-avatar"), jpg)
      end)
      |> assert_has(text("phx-change triggered on file selection", exact: true))
    end

    test "upload follows redirects from progress callbacks (#{driver})" do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> session()
      |> visit("/live/uploads")
      |> within(css("#upload-redirect-form"), fn scoped ->
        upload(scoped, "Redirect Avatar", jpg)
      end)
      |> assert_path("/live/async_page_2")
    end
  end

  defp upload_fixture_path(file_name) do
    "test/support/files/#{file_name}"
  end
end
