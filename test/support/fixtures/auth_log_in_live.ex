defmodule Cerberus.Fixtures.AuthLogInLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures.AuthHelpers

  @impl true
  def mount(_params, session, socket) do
    case AuthHelpers.current_user_from_session(session) do
      {:ok, _user} ->
        {:ok, redirect(socket, to: "/auth/live/dashboard")}

      :error ->
        {:ok,
         assign(socket,
           email: "",
           password: "",
           trigger_submit: false
         )}
    end
  end

  @impl true
  def handle_event("log_in", %{"user" => params}, socket) do
    {:noreply,
     assign(socket,
       email: Map.get(params, "email", ""),
       password: Map.get(params, "password", ""),
       trigger_submit: true
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Log in</h1>
      <form
        id="live-log-in-form"
        action="/auth/users/log_in"
        method="post"
        phx-submit="log_in"
        phx-trigger-action={@trigger_submit}
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <input type="hidden" name="user[return_to]" value="/auth/live/dashboard" />

        <label for="live_auth_log_in_email">Email</label>
        <input id="live_auth_log_in_email" name="user[email]" type="email" value={@email} />

        <label for="live_auth_log_in_password">Password</label>
        <input id="live_auth_log_in_password" name="user[password]" type="password" value={@password} />

        <button type="submit">Log in</button>
      </form>
    </main>
    """
  end
end
