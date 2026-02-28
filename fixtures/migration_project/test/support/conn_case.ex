defmodule MigrationFixtureWeb.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import MigrationFixtureWeb.ConnCase
      import Phoenix.ConnTest

      @endpoint MigrationFixtureWeb.Endpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
