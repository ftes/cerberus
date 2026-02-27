defmodule Cerberus.Fixtures.OracleMismatchLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <p>Oracle mismatch live fixture marker</p>
    </main>
    """
  end
end
