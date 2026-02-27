defmodule Cerberus.Fixtures.LiveSandbox do
  @moduledoc false

  import Phoenix.Component, only: [assign_new: 3]
  import Phoenix.LiveView, only: [connected?: 1, get_connect_info: 2]

  alias Phoenix.LiveView.Socket

  @spec on_mount(:default, map(), map(), Socket.t()) ::
          {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    socket =
      assign_new(socket, :phoenix_ecto_sandbox, fn ->
        if connected?(socket), do: get_connect_info(socket, :user_agent)
      end)

    Phoenix.Ecto.SQL.Sandbox.allow(socket.assigns.phoenix_ecto_sandbox, Ecto.Adapters.SQL.Sandbox)
    {:cont, socket}
  end
end
