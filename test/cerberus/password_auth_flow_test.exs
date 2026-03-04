defmodule Cerberus.PasswordAuthFlowTest do
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
    test "static password auth supports sign up, log in, and log out (#{driver})", context do
      email = unique_email("static")
      password = "Password12345!"

      unquote(driver)
      |> driver_session(context)
      |> visit("/auth/static/users/register")
      |> fill_in(label("Email"), email)
      |> fill_in(label("Password"), password)
      |> fill_in(label("Confirm Password"), password)
      |> submit(button("Create account"))
      |> assert_path("/auth/static/dashboard")
      |> assert_has(text("Signed in as: #{email}", exact: true))
      |> submit(button("Log out"))
      |> assert_path("/auth/static/users/log_in")
      |> fill_in(label("Email"), email)
      |> fill_in(label("Password"), password)
      |> submit(button("Log in"))
      |> assert_path("/auth/static/dashboard")
      |> assert_has(text("Signed in as: #{email}", exact: true))
      |> submit(button("Log out"))
      |> assert_path("/auth/static/users/log_in")
    end

    test "live password auth supports sign up, log in, and log out (#{driver})", context do
      email = unique_email("live")
      password = "Password12345!"

      unquote(driver)
      |> driver_session(context)
      |> visit("/auth/live/users/register")
      |> fill_in(label("Email"), email)
      |> fill_in(label("Password"), password)
      |> fill_in(label("Confirm Password"), password)
      |> submit(button("Create live account"))
      |> assert_path("/auth/live/dashboard")
      |> assert_has(text("Live dashboard for: #{email}", exact: true))
      |> submit(button("Log out"))
      |> assert_path("/auth/live/users/log_in")
      |> fill_in(label("Email"), email)
      |> fill_in(label("Password"), password)
      |> submit(button("Log in"))
      |> assert_path("/auth/live/dashboard")
      |> assert_has(text("Live dashboard for: #{email}", exact: true))
      |> submit(button("Log out"))
      |> assert_path("/auth/live/users/log_in")
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)

  defp unique_email(prefix) when is_binary(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}@example.com"
  end
end
