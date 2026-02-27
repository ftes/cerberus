defmodule Cerberus.Fixtures.RedirectsLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("to_articles", _params, socket) do
    {:noreply, push_navigate(socket, to: "/articles")}
  end

  @impl true
  def handle_event("to_counter", _params, socket) do
    {:noreply, push_navigate(socket, to: "/live/counter")}
  end

  @impl true
  def handle_event("patch_self", _params, socket) do
    {:noreply, push_patch(socket, to: "/live/redirects?details=true&foo=bar")}
  end

  @impl true
  def handle_event("to_counter_with_query", _params, socket) do
    {:noreply, push_navigate(socket, to: "/live/counter?foo=bar")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Redirects</h1>
      <button phx-click="to_articles">Redirect to Articles</button>
      <button phx-click="to_counter">Redirect to Counter</button>
      <button phx-click="patch_self">Patch link</button>
      <button phx-click="to_counter_with_query">Button with push navigation</button>
    </main>
    """
  end
end
