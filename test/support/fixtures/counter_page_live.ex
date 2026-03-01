defmodule Cerberus.Fixtures.CounterPageLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    timezone =
      if Phoenix.LiveView.connected?(socket) do
        socket |> Phoenix.LiveView.get_connect_params() |> Map.get("timezone", "unset")
      else
        "unset"
      end

    {:ok, socket |> assign(:count, 0) |> assign(:timezone, timezone)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Counter</h1>
      <p>Count: <%= @count %></p>
      <p style="display:none">Hidden live helper text</p>
      <p id="connect-timezone">connect timezone: <%= @timezone %></p>
      <a href="/articles">Articles</a>
      <button phx-click="increment">Increment</button>
    </main>
    """
  end
end
