defmodule Cerberus.ExplicitBrowserTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser.Runtime

  test "browser session runs as expected" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> assert_has(text("Articles", exact: true))

    assert session.tab_id
  end

  test "browser session uses the configured runtime" do
    expected_runtime =
      []
      |> Runtime.browser_name()
      |> browser_user_agent_fragment()

    :browser
    |> session()
    |> Cerberus.Browser.with_evaluate_js("navigator.userAgent", fn user_agent ->
      assert user_agent =~ expected_runtime
    end)
  end

  test "slow_mo delays browser command dispatch" do
    session =
      :browser
      |> session(slow_mo: 120)
      |> visit("/articles")

    started_at = System.monotonic_time(:millisecond)
    assert session == Cerberus.Browser.with_evaluate_js(session, "1 + 1", &assert(&1 == 2))
    elapsed_ms = System.monotonic_time(:millisecond) - started_at

    assert elapsed_ms >= 100
  end

  defp browser_user_agent_fragment(:chrome), do: "Chrome"
  defp browser_user_agent_fragment(:firefox), do: "Firefox"
end
