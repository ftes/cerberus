defmodule Cerberus.CoreCrossDriverTextTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Fixtures
  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:static, :live, :browser]

  test "text assertions behave consistently across all drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit(Fixtures.articles_path())
      |> assert_has(text: Fixtures.articles_title())
      |> assert_has(~r/articles index/i)
      |> refute_has(text: "500 Internal Server Error")
      |> assert_has([text: Fixtures.hidden_helper_text()], visible: false)
    end)
  end
end
