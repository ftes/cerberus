defmodule Cerberus.Fixtures.RedirectsLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("to_articles", _params, socket) do
    {:noreply, push_navigate(socket, to: Fixtures.articles_path())}
  end

  @impl true
  def handle_event("to_counter", _params, socket) do
    {:noreply, push_navigate(socket, to: Fixtures.counter_path())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Redirects</h1>
      <button phx-click="to_articles"><%= Fixtures.redirect_to_articles_button() %></button>
      <button phx-click="to_counter"><%= Fixtures.redirect_to_counter_button() %></button>
    </main>
    """
  end
end
