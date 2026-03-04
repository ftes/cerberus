defmodule Cerberus.LiveUploadBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  test "upload keeps active form unset and raises translated upload errors" do
    jpg = upload_fixture_path("elixir.jpg")
    png = upload_fixture_path("phoenix.png")

    session =
      :phoenix
      |> session()
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, label("Avatar"), jpg)
      end)

    assert %{active_form: nil} = session.form_data

    assert_raise ExUnit.AssertionError, ~r/Unsupported file type/, fn ->
      session
      |> visit("/live/uploads")
      |> within(css("#full-form"), fn scoped ->
        upload(scoped, label("Avatar"), png)
      end)
    end

    assert_raise ExUnit.AssertionError, ~r/Too many files uploaded/, fn ->
      session
      |> visit("/live/uploads")
      |> within(css("#full-form"), fn scoped ->
        scoped
        |> upload(label("Avatar"), jpg)
        |> upload(label("Avatar"), jpg)
      end)
    end

    assert_raise ExUnit.AssertionError, ~r/File too large/, fn ->
      session
      |> visit("/live/uploads")
      |> within(css("#tiny-upload-form"), fn scoped ->
        upload(scoped, label("Tiny"), jpg)
      end)
    end
  end

  for driver <- [:phoenix, :browser] do
    test "upload triggers phx-change validations on file selection (#{driver})", context do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> driver_session(context)
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, label("Avatar"), jpg)
      end)
      |> assert_has(text("phx-change triggered on file selection", exact: true))
    end

    test "upload supports testid locators on live file inputs (#{driver})", context do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> driver_session(context)
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, testid("live-upload-change-avatar"), jpg)
      end)
      |> assert_has(text("phx-change triggered on file selection", exact: true))
    end

    test "upload follows redirects from progress callbacks (#{driver})", context do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> driver_session(context)
      |> visit("/live/uploads")
      |> within(css("#upload-redirect-form"), fn scoped ->
        upload(scoped, label("Redirect Avatar"), jpg)
      end)
      |> assert_path("/live/async_page_2")
    end
  end

  defp upload_fixture_path(file_name) do
    "test/support/files/#{file_name}"
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
