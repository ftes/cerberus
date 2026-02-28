defmodule MigrationFixtureWeb.LiveNavLive do
  @moduledoc false
  use MigrationFixtureWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :step, "0")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    step = Map.get(params, "step", "0")
    {:noreply, assign(socket, :step, step)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Live Nav</h1>
      <p id="step">Step: <%= @step %></p>
      <.link patch="/live-nav?step=1">Patch Step 1</.link>
      <.link navigate="/counter">Navigate Counter</.link>
    </div>
    """
  end
end
