defmodule Cerberus.CoreBrowserCrossBrowserRuntimeTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag browser: true
  @moduletag drivers: [:chrome, :firefox]

  test "chrome and firefox lanes execute in one test invocation", context do
    results =
      Harness.run!(context, fn session ->
        session =
          session
          |> visit("/articles")
          |> assert_has(text("Articles", exact: true))

        %{browser_name: session.browser_name, user_agent: user_agent(session)}
      end)

    assert Enum.map(results, & &1.driver) == [:chrome, :firefox]

    chrome = Enum.find(results, &(&1.driver == :chrome))
    firefox = Enum.find(results, &(&1.driver == :firefox))

    assert chrome.value.browser_name == :chrome
    assert firefox.value.browser_name == :firefox
    assert chrome.value.user_agent =~ "Chrome"
    assert firefox.value.user_agent =~ "Firefox"
  end

  defp user_agent(session) do
    expression = ~s|(() => navigator.userAgent)()|

    case UserContextProcess.evaluate(session.user_context_pid, expression, session.tab_id) do
      {:ok, %{"result" => %{"type" => "string", "value" => value}}} when is_binary(value) ->
        value

      {:ok, result} ->
        raise "unexpected user-agent payload: #{inspect(result)}"

      {:error, reason, details} ->
        raise "failed to read user-agent: #{reason} (#{inspect(details)})"
    end
  end
end
