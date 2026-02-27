defmodule Cerberus.Fixtures.NestedChildLive do
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
    <section class="child-pane">
      <h2>Child LiveView</h2>
      <div class="actions child-actions">
        <button phx-click="save">Save</button>
      </div>
      <p id="child-view-form-data">Child saved: <%= @saved %></p>
    </section>
    """
  end
end
