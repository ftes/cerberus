defmodule Cerberus.CoreSQLSandboxBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Fixtures.SandboxMessages
  alias Cerberus.Harness
  alias Cerberus.Session

  @moduletag drivers: [:static, :live, :browser]

  test "sandbox metadata keeps static DB reads isolated across drivers", context do
    Harness.run!(
      context,
      fn session ->
        body = unique_message("static", session)
        SandboxMessages.insert!(body)

        session
        |> visit("/sandbox/messages")
        |> assert_has(text(body, exact: true))
      end,
      sandbox: true
    )
  end

  @tag drivers: [:live, :browser]
  test "sandbox metadata keeps live DB reads isolated across drivers", context do
    Harness.run!(
      context,
      fn session ->
        body = unique_message("live", session)
        SandboxMessages.insert!(body)

        session
        |> visit("/live/sandbox/messages")
        |> assert_has(text(body, exact: true))
        |> click_button(button("Refresh", exact: true))
        |> assert_has(text(body, exact: true))
      end,
      sandbox: true
    )
  end

  defp unique_message(prefix, session) do
    "#{prefix}-#{Session.driver_kind(session)}-#{System.unique_integer([:positive, :monotonic])}"
  end
end
