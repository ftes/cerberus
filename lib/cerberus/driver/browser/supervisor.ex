defmodule Cerberus.Driver.Browser.Supervisor do
  @moduledoc false

  use Supervisor

  @user_context_supervisor Cerberus.Driver.Browser.UserContextSupervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Cerberus.Driver.Browser.Runtime, []},
      {Cerberus.Driver.Browser.BiDiSupervisor, []},
      {DynamicSupervisor, strategy: :one_for_one, name: @user_context_supervisor}
    ]

    # Runtime restart invalidates shared transport/userContext state, so downstream
    # children are restarted in declaration order.
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
