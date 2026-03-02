defmodule Cerberus.Playwright.Case do
  @moduledoc """
  ExUnit case template for browser-first tests and migrated Playwright case modules.

  This template imports `Cerberus` and `Cerberus.Browser` and injects a browser
  session into test context as both `:session` and `:conn` to keep migrated
  `conn |> ...` pipelines runnable.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Cerberus
      import Cerberus.Browser
    end
  end

  setup _tags do
    session = Cerberus.session(:browser)
    {:ok, session: session, conn: session}
  end
end
