defmodule Cerberus.CrossDriverMultiTabUserTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "multi-tab sharing and multi-user isolation work with one API across drivers (#{driver})" do
      primary =
        unquote(driver)
        |> session()
        |> visit("/session/user/alice")
        |> assert_has(text("Session user: alice", exact: true))

      secondary_tab =
        primary
        |> open_tab()
        |> visit("/session/user")
        |> assert_has(text("Session user: alice", exact: true))
        |> visit("/live/counter")
        |> click(button("Increment"))
        |> assert_has(text("Count: 1", exact: true))

      primary =
        secondary_tab
        |> switch_tab(primary)
        |> assert_has(text("Session user: alice", exact: true))

      isolated_user =
        unquote(driver)
        |> session()
        |> visit("/session/user")
        |> assert_has(text("Session user: unset", exact: true))
        |> visit("/session/user/bob")
        |> assert_has(text("Session user: bob", exact: true))

      isolated_tab =
        isolated_user
        |> open_tab()
        |> visit("/session/user")
        |> assert_has(text("Session user: bob", exact: true))

      primary = assert_has(primary, text("Session user: alice", exact: true))

      close_tab(isolated_tab)
      assert_has(primary, text("Session user: alice", exact: true))
    end
  end
end
