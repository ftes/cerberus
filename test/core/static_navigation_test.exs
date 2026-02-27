defmodule Cerberus.CoreStaticNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Fixtures
  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:static]

  test "static driver supports link navigation into deterministic page state", context do
    Harness.run!(context, fn session ->
      session
      |> visit(Fixtures.articles_path())
      |> click(text: Fixtures.counter_link())
      |> assert_has([text: Fixtures.counter_text(0)], exact: true)
    end)
  end

  test "static driver rejects dynamic button interactions", context do
    results =
      Harness.run(context, fn session ->
        session
        |> visit(Fixtures.counter_path())
        |> click(text: Fixtures.increment_button())
      end)

    assert [%{driver: :static, status: :error, message: message}] = results
    assert message =~ "static driver does not support dynamic button clicks"
  end

  test "static redirects are deterministic and stay inside fixture routes", context do
    Harness.run!(context, fn session ->
      session
      |> visit(Fixtures.static_redirect_path())
      |> assert_has(text: Fixtures.articles_title())
      |> visit(Fixtures.live_redirect_path())
      |> assert_has([text: Fixtures.counter_text(0)], exact: true)
    end)
  end
end
