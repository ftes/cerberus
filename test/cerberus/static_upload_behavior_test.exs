defmodule Cerberus.StaticUploadBehaviorTest do
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

  for driver <- [:phoenix, :browser] do
    test "upload and submit support testid locators on static routes (#{driver})", context do
      jpg = upload_fixture_path("elixir.jpg")

      unquote(driver)
      |> driver_session(context)
      |> visit("/upload/static")
      |> within(css("#static-upload-form"), fn scoped ->
        scoped
        |> upload(testid("static-avatar-upload"), jpg)
        |> submit(testid("static-upload-submit"))
      end)
      |> assert_has(text("Uploaded file: elixir.jpg", exact: true))
    end
  end

  defp upload_fixture_path(file_name) do
    "test/support/files/#{file_name}"
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
