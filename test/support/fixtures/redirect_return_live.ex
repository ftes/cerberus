defmodule Cerberus.Fixtures.RedirectReturnLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, push_navigate(socket, to: "/live/redirects?navigated_back=true")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <p>Redirecting...</p>
    </main>
    """
  end
end
