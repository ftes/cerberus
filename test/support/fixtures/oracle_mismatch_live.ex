defmodule Cerberus.Fixtures.OracleMismatchLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <p><%= Fixtures.oracle_live_marker() %></p>
    </main>
    """
  end
end
