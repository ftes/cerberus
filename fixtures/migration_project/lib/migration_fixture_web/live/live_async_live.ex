defmodule MigrationFixtureWeb.LiveAsyncLive do
  @moduledoc false
  use MigrationFixtureWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :status, "idle")}
  end

  @impl true
  def handle_event("start", _params, socket) do
    socket =
      socket
      |> assign(:status, "pending")
      |> start_async(:status_job, fn ->
        Process.sleep(30)
        "done"
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:status_job, {:ok, value}, socket) do
    {:noreply, assign(socket, :status, value)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Live Async</h1>
      <button type="button" phx-click="start">Start Async</button>
      <p id="async-status">Async Status: <%= @status %></p>
    </div>
    """
  end
end
