defmodule Cerberus.Fixtures.PortalLive do
  @moduledoc false
  use Phoenix.LiveView

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
    <main>
      <h1>Portal Example</h1>
      <p id="outside-count">Outside count: <%= @count %></p>
      <div id="portal-target"></div>

      <.portal id="portal-counter" target="#portal-target">
        <section id="portal-panel">
          <p id="portal-count">Portal count: <%= @count %></p>
          <button phx-click="increment">Increment portal</button>
        </section>
      </.portal>
    </main>
    """
  end
end
