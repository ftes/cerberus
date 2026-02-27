defmodule Cerberus.Fixtures.SandboxMessagesLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures.SandboxMessages

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :messages, SandboxMessages.list_bodies())}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, assign(socket, :messages, SandboxMessages.list_bodies())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Sandbox messages live</h1>
      <button type="button" phx-click="refresh">Refresh</button>
      <ul id="sandbox-messages-live">
        <%= for body <- @messages do %>
          <li class="sandbox-message"><%= body %></li>
        <% end %>
      </ul>
    </main>
    """
  end
end
