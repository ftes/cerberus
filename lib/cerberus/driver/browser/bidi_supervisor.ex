defmodule Cerberus.Driver.Browser.BiDiSupervisor do
  @moduledoc false

  use Supervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Cerberus.Driver.Browser.BiDiSocket, owner: Cerberus.Driver.Browser.BiDi},
      {Cerberus.Driver.Browser.BiDi, []}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
