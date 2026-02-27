defmodule Cerberus.Fixtures.AsyncPage2Live do
  @moduledoc false
  use Phoenix.LiveView

  @assign_delay_ms 120

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :title, "Loading another async title...")

    if connected?(socket) do
      Process.send_after(self(), :load_title, @assign_delay_ms)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:load_title, socket) do
    {:noreply, assign(socket, :title, "Another title loaded async")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1><%= @title %></h1>
    </main>
    """
  end
end
