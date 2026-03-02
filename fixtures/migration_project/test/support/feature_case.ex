defmodule MigrationFixtureWeb.FeatureCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      use MigrationFixtureWeb.ConnCase, async: true
      import PhoenixTest
    end
  end
end
