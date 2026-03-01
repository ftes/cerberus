defmodule CerberusTest.LiveLinkNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Phoenix.ConnTest, only: [build_conn: 0]

  for driver <- [:phoenix, :browser] do
    test "click_link handles live navigate, patch, and non-live transitions (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/redirects")
      |> click_link(link("Navigate link", exact: true))
      |> assert_path("/live/counter")
      |> assert_has(text("Count: 0", exact: true))
      |> visit("/live/redirects")
      |> click_link(link("Patch link", exact: true))
      |> assert_path("/live/redirects", query: [details: "true", foo: "bar"])
      |> assert_has(text("Live Redirects Details", exact: true))
      |> click_link(link("Navigate to non-liveview", exact: true))
      |> assert_path("/main")
      |> assert_has(text("Main page", exact: true))
    end

    test "click_link follows navigation that redirects back with flash (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/redirects")
      |> click_link(link("Navigate (and redirect back) link", exact: true))
      |> assert_path("/live/redirects")
      |> assert_has(text("Live Redirects", exact: true))
      |> assert_has(text("Navigated back!", exact: true))
    end
  end

  test "live click_link preserves request headers across non-live navigation" do
    seed_conn = Plug.Conn.put_req_header(build_conn(), "x-custom-header", "Some-Value")

    :phoenix
    |> session(conn: seed_conn)
    |> visit("/live/redirects")
    |> click_link(link("Navigate to non-liveview", exact: true))
    |> assert_path("/main")
    |> assert_has(text("Main page", exact: true))
    |> assert_has(text("x-custom-header: Some-Value", exact: true))
    |> then(fn updated_session ->
      assert {"x-custom-header", "Some-Value"} in updated_session.conn.req_headers
      updated_session
    end)
  end

  test "live click_link preserves connect_params across live navigation" do
    seed_conn = Phoenix.LiveViewTest.put_connect_params(build_conn(), %{"timezone" => "Europe/Berlin"})

    :phoenix
    |> session(conn: seed_conn)
    |> visit("/live/redirects")
    |> assert_has(text("connect timezone: Europe/Berlin", exact: true))
    |> click_link(link("Navigate link", exact: true))
    |> assert_path("/live/counter")
    |> assert_has(text("connect timezone: Europe/Berlin", exact: true))
    |> then(fn updated_session ->
      assert updated_session.conn.private[:live_view_connect_params] == %{"timezone" => "Europe/Berlin"}
      updated_session
    end)
  end
end
