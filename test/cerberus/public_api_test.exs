defmodule Cerberus.PublicApiTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.InvalidLocatorError

  test "session constructor returns per-driver structs for non-browser drivers" do
    assert %StaticSession{} = session(:static)
    assert %LiveSession{} = session(:live)
    assert %StaticSession{} = session(:auto)
  end

  @tag browser: true
  test "session constructor returns a browser session" do
    assert %BrowserSession{} = session(:browser)
  end

  test "assert_has with unsupported locator raises InvalidLocatorError" do
    assert_raise InvalidLocatorError, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> assert_has(foo: "bar")
    end
  end

  test "assert_has accepts text sigil locator" do
    assert is_struct(
             :static
             |> session()
             |> visit("/articles")
             |> assert_has(~l"Articles")
           )
  end

  test "unsupported driver is rejected" do
    assert_raise ArgumentError, ~r/unsupported driver/, fn ->
      session(:unknown)
    end
  end

  test "fill_in accepts positional value argument" do
    assert is_struct(
             :static
             |> session()
             |> visit("/search")
             |> fill_in([text: "Search term"], "phoenix")
           )
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
