defmodule Cerberus.Fixtures.RedirectsLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, details: false, flash_message: nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    details? = params["details"] == "true"
    flash_message = if params["navigated_back"] == "true", do: "Navigated back!"
    {:noreply, assign(socket, details: details?, flash_message: flash_message)}
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
  def handle_event("hard_redirect_to_articles", _params, socket) do
    {:noreply, redirect(socket, to: "/articles")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Redirects</h1>
      <div id="flash-group"><%= @flash_message %></div>

      <%= if @details do %>
        <h2>Live Redirects Details</h2>
      <% end %>

      <.link navigate="/live/counter">Navigate link</.link>
      <.link navigate="/live/redirect-return">Navigate (and redirect back) link</.link>
      <.link patch="/live/redirects?details=true&foo=bar">Patch link</.link>
      <a href="/main">Navigate to non-liveview</a>

      <button phx-click="to_articles">Redirect to Articles</button>
      <button phx-click="to_counter">Redirect to Counter</button>
      <button phx-click="patch_self">Patch link</button>
      <button phx-click="to_counter_with_query">Button with push navigation</button>
      <button phx-click="hard_redirect_to_articles">Hard Redirect to Articles</button>
    </main>
    """
  end
end
