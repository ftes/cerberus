defmodule MigrationFixtureWeb.LiveChangeLive do
  @moduledoc false
  use MigrationFixtureWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :name, "")}
  end

  @impl true
  def handle_event("form-change", %{"profile" => %{"name" => name}}, socket) do
    {:noreply, assign(socket, :name, name)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Live Change</h1>
      <form phx-change="form-change">
        <label for="profile_name">Name</label>
        <input id="profile_name" name="profile[name]" type="text" value={@name} />
      </form>
      <p id="change-result">Changed: <%= @name %></p>
    </div>
    """
  end
end
