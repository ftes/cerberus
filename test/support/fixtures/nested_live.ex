defmodule Cerberus.Fixtures.NestedLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :saved, 0)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, update(socket, :saved, &(&1 + 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Nested LiveView</h1>
      <div class="actions parent-actions">
        <button phx-click="save">Save</button>
      </div>
      <p id="parent-view-form-data">Parent saved: <%= @saved %></p>

      {live_render(@socket, Cerberus.Fixtures.NestedChildLive, id: "child-live-view")}
    </main>
    """
  end
end
