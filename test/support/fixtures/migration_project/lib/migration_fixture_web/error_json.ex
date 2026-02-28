defmodule MigrationFixtureWeb.ErrorJSON do
  @moduledoc false

  def render(_template, _assigns), do: %{errors: %{detail: "error"}}
end
