defmodule Cerberus.FormActionsTest do
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
    test "click_link, fill_in, and submit are consistent across static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> click(text: "Articles")
      |> assert_has(text: "Articles", exact: true)
      |> visit("/search")
      |> fill_in(label("Search term"), "phoenix")
      |> submit(text: "Run Search")
      |> assert_has(text: "Search query: phoenix", exact: true)
    end

    test "submit/1 submits the active form (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(label("Search term *"), "compat")
      |> submit()
      |> assert_has(text: "Nested search query: compat", exact: true)
    end

    test "submit/1 fails when no active form exists (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/requires an active form/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/search")
        |> submit()
      end
    end

    test "fill_in matches wrapped labels with nested inline text across static and browser drivers (#{driver})",
         context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(label("Search term *"), "phoenix")
      |> submit(text: "Run Nested Search")
      |> assert_has(text: "Nested search query: phoenix", exact: true)
    end

    test "submit normalizes nested form params for non-GET requests (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/nested-submit")
      |> fill_in(label("Email"), "someone-1@teamengine.co.uk")
      |> fill_in(label("Password"), "Pass123456789!")
      |> submit(text: "Sign In")
      |> assert_has(text: "session.email: someone-1@teamengine.co.uk", exact: true)
      |> assert_has(text: "session.password: Pass123456789!", exact: true)
      |> assert_has(text: "flat session[email] key?: false", exact: true)
      |> assert_has(text: "flat session[password] key?: false", exact: true)
    end

    test "click_button works on live counter flow for live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click(text: "Increment")
      |> assert_has(text: "Count: 1", exact: true)
    end

    test "action failures include possible candidate hints (#{driver})", context do
      click_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> click(text: "Definitely Missing Link")
        end

      assert click_error.message =~ "possible candidates:"
      assert click_error.message =~ "Articles"

      fill_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> fill_in(label("Definitely Missing Field"), "x")
        end

      assert fill_error.message =~ "possible candidates:"
      assert fill_error.message =~ "Search term"

      submit_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> submit(text: "Definitely Missing Submit")
        end

      assert submit_error.message =~ "possible candidates:"
      assert submit_error.message =~ "Run Search"
    end

    test "role locator failures include possible candidate hints (#{driver})", context do
      role_click_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> click(role(:link, name: "Definitely Missing Link"))
        end

      assert role_click_error.message =~ "possible candidates:"
      assert role_click_error.message =~ "Articles"
    end
  end

  test "submit/1 can submit active live forms without a submit button when phx-submit is defined (phoenix)" do
    :phoenix
    |> session()
    |> visit("/live/form-change")
    |> fill_in(label("No button name"), "Arnor")
    |> submit()
    |> assert_has(text("No button submit: Arnor", exact: true))
  end

  test "submit/1 errors when active live form has neither phx-submit nor action (phoenix)" do
    assert_raise ExUnit.AssertionError, ~r/`phx-submit` or `action` defined/, fn ->
      :phoenix
      |> session()
      |> visit("/live/form-change")
      |> fill_in(label("Name (no phx-change)"), "Arnor")
      |> submit()
    end
  end

  test "submit/1 keeps active live form values when conditional fields are removed (phoenix)" do
    :phoenix
    |> session()
    |> visit("/phoenix_test/live/index")
    |> fill_in(label("To keep"), "this input should stay")
    |> fill_in(label("To remove"), "this input will now be removed")
    |> submit()
    |> check(label("Hide to remove"))
    |> submit()
    |> assert_has("#form-data" |> css() |> text("this input should stay", exact: false))
    |> refute_has("#form-data" |> css() |> text("this input will now be removed", exact: false))
  end

  @tag skip: "browser submit-active-form-no-button parity bug"
  test "submit/1 parity for no-button live forms in browser driver" do
    :browser
    |> session()
    |> visit("/live/form-change")
    |> fill_in(label("No button name"), "Arnor")
    |> submit()
    |> assert_has(text("No button submit: Arnor", exact: true))
  end

  test "live driver reports missing fields for fill_in and missing submit controls on counter page" do
    assert_raise ExUnit.AssertionError, ~r/no form field matched locator/, fn ->
      :phoenix
      |> session()
      |> visit("/live/counter")
      |> fill_in(label("Search term"), "x")
    end

    assert_raise ExUnit.AssertionError, ~r/no submit button matched locator/, fn ->
      :phoenix
      |> session()
      |> visit("/live/counter")
      |> submit(text: "Run Search")
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
