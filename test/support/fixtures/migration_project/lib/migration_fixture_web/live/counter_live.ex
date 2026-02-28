defmodule MigrationFixtureWeb.CounterLive do
  @moduledoc false
  use MigrationFixtureWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Counter</h1>
      <button type="button" phx-click="increment">Increment</button>
      <p id="count"><%= @count %></p>
    </div>
    """
  end
end
