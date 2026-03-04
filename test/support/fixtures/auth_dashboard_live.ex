defmodule Cerberus.Fixtures.AuthDashboardLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures.AuthHelpers

  @impl true
  def mount(_params, session, socket) do
    case AuthHelpers.current_user_from_session(session) do
      {:ok, user} ->
        {:ok, assign(socket, current_user_email: user.email)}

      :error ->
        {:ok, redirect(socket, to: "/auth/live/users/log_in")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Auth Dashboard</h1>
      <p>Live dashboard for: <%= @current_user_email %></p>

      <form id="live-log-out-form" action="/auth/users/log_out" method="post">
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <input type="hidden" name="return_to" value="/auth/live/users/log_in" />
        <button type="submit">Log out</button>
      </form>
    </main>
    """
  end
end
