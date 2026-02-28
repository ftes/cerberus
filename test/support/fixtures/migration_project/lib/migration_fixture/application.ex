defmodule MigrationFixture.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: MigrationFixture.PubSub},
      MigrationFixtureWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MigrationFixture.Supervisor)
  end

  @impl true
  def config_change(changed, removed, _extra) do
    MigrationFixtureWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
