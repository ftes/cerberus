defmodule MigrationFixtureWeb.ErrorHTML do
  @moduledoc false

  use MigrationFixtureWeb, :html

  def render(_template, _assigns), do: "error"
end
