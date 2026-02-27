defmodule Cerberus.CoreLiveNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Fixtures
  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:live, :browser]

  test "dynamic counter updates are consistent between live and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit(Fixtures.counter_path())
      |> click(text: Fixtures.increment_button())
      |> assert_has([text: Fixtures.counter_text(1)], exact: true)
    end)
  end

  test "live redirects are deterministic in live and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit(Fixtures.live_redirects_path())
      |> click(text: Fixtures.redirect_to_articles_button())
      |> assert_has(text: Fixtures.articles_title())
      |> visit(Fixtures.live_redirects_path())
      |> click(text: Fixtures.redirect_to_counter_button())
      |> assert_has([text: Fixtures.counter_text(0)], exact: true)
    end)
  end
end
