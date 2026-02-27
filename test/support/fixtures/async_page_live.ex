defmodule Cerberus.Fixtures.AsyncPageLive do
  @moduledoc false
  use Phoenix.LiveView

  @assign_delay_ms 120
  @nav_delay_ms 80

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:title, "Loading async title...")
      |> assign(:description, "Where we test LiveView's async behavior")

    if connected?(socket) do
      Process.send_after(self(), :load_title, @assign_delay_ms)
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("async_navigate", _params, socket) do
    Process.send_after(self(), :async_navigate, @nav_delay_ms)
    {:noreply, socket}
  end

  @impl true
  def handle_event("async_navigate_to_async_2", _params, socket) do
    Process.send_after(self(), :async_navigate_to_async_2, @nav_delay_ms)
    {:noreply, socket}
  end

  @impl true
  def handle_event("async_redirect", _params, socket) do
    Process.send_after(self(), :async_redirect, @nav_delay_ms)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_title, socket) do
    {:noreply, assign(socket, :title, "Title loaded async")}
  end

  @impl true
  def handle_info(:async_navigate, socket) do
    {:noreply, push_navigate(socket, to: "/live/counter")}
  end

  @impl true
  def handle_info(:async_navigate_to_async_2, socket) do
    {:noreply, push_navigate(socket, to: "/live/async_page_2")}
  end

  @impl true
  def handle_info(:async_redirect, socket) do
    {:noreply, redirect(socket, to: "/articles")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1><%= @title %></h1>
      <h2><%= @description %></h2>

      <button phx-click="async_navigate">Async navigate!</button>
      <button phx-click="async_navigate_to_async_2">Async navigate to async 2 page!</button>
      <button phx-click="async_redirect">Async redirect!</button>
    </main>
    """
  end
end
