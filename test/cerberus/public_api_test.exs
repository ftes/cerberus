defmodule Cerberus.PublicApiTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.InvalidLocatorError
  alias Cerberus.Session

  test "session constructor returns a session for static and live drivers" do
    assert %Session{driver: :static} = session(:static)
    assert %Session{driver: :live} = session(:live)
  end

  @tag browser: true
  test "session constructor returns a browser session" do
    assert %Session{driver: :browser} = session(:browser)
  end

  test "assert_has with unsupported locator raises InvalidLocatorError" do
    assert_raise InvalidLocatorError, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> assert_has(foo: "bar")
    end
  end

  test "unsupported driver is rejected" do
    assert_raise ArgumentError, ~r/unsupported driver/, fn ->
      session(:unknown)
    end
  end

  test "fill_in accepts positional value argument" do
    assert %Session{} =
             :static
             |> session()
             |> visit("/search")
             |> fill_in([text: "Search term"], "phoenix")
  end

  test "invalid keyword options are rejected via NimbleOptions" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> click([text: "Articles"], kind: :nope)
    end
  end

  test "reload_page revisits the current path" do
    session =
      :static
      |> session()
      |> visit("/articles")

    reloaded = reload_page(session)

    assert reloaded.current_path == "/articles"
  end
end
