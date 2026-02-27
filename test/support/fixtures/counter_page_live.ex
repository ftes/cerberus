defmodule Cerberus.Fixtures.CounterPageLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures

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
      <h1><%= Fixtures.counter_title() %></h1>
      <p><%= Fixtures.counter_text(@count) %></p>
      <a href={Fixtures.articles_path()}><%= Fixtures.articles_link() %></a>
      <button phx-click="increment"><%= Fixtures.increment_button() %></button>
    </main>
    """
  end
end
