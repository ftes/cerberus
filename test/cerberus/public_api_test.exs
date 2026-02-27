defmodule Cerberus.PublicApiTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.InvalidLocatorError
  alias Cerberus.Session

  test "session constructor returns a session for each driver" do
    assert %Session{driver: :static} = session(:static)
    assert %Session{driver: :live} = session(:live)
    assert %Session{driver: :browser} = session(:browser)
  end

  test "assert_has with unsupported locator raises InvalidLocatorError" do
    assert_raise InvalidLocatorError, fn ->
      session(:static)
      |> visit("/articles")
      |> assert_has(foo: "bar")
    end
  end

  test "unsupported driver is rejected" do
    assert_raise ArgumentError, ~r/unsupported driver/, fn ->
      session(:unknown)
    end
  end
end
