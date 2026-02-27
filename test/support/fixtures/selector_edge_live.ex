defmodule Cerberus.Fixtures.SelectorEdgeLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, selected: "none")}
  end

  @impl true
  def handle_event("select_primary", _params, socket) do
    {:noreply, assign(socket, :selected, "primary")}
  end

  @impl true
  def handle_event("select_secondary", _params, socket) do
    {:noreply, assign(socket, :selected, "secondary")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Selector Edge</h1>
      <p id="selected-result">Selected: <%= @selected %></p>
      <a href="/articles">Articles</a>

      <button phx-click="select_primary" class="action primary" data-kind={"p\"a\\th"}>
        Apply
      </button>

      <button phx-click="select_secondary" class="action secondary" data-kind="secondary">
        Apply
      </button>
    </main>
    """
  end
end
