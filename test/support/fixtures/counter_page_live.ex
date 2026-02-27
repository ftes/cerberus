defmodule Cerberus.Fixtures.CounterPageLive do
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
      <h1>Counter</h1>
      <p>Count: <%= @count %></p>
      <a href="/articles">Articles</a>
      <button phx-click="increment">Increment</button>
    </main>
    """
  end
end
