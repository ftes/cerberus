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
  def handle_event("select_confirm", _params, socket) do
    {:noreply, assign(socket, :selected, "confirmed")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Selector Edge</h1>
      <p id="selected-result">Selected: <%= @selected %></p>
      <a href="/articles">Articles</a>

      <section id="primary-actions">
        <button phx-click="select_primary" class="action primary" data-kind={"p\"a\\th"} data-testid="apply-primary">
          Apply
        </button>
      </section>

      <section id="secondary-actions">
        <button phx-click="select_secondary" class="action secondary" data-kind="secondary" data-testid="apply-secondary">
          Apply
        </button>
      </section>

      <section id="confirm-actions">
        <button phx-click="select_confirm" data-confirm={"Are you sure?\nMore text"}>
          Create
        </button>
      </section>

      <section id="role-actions">
        <button phx-click="select_primary" role="tab">Tab Primary</button>
        <button phx-click="select_secondary" role="menuitem">Menu Secondary</button>
      </section>
    </main>
    """
  end
end
