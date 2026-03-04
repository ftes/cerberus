defmodule Cerberus.Fixtures.AuthRegisterLive do
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
           password_confirmation: "",
           trigger_submit: false
         )}
    end
  end

  @impl true
  def handle_event("register", %{"user" => params}, socket) do
    {:noreply,
     assign(socket,
       email: Map.get(params, "email", ""),
       password: Map.get(params, "password", ""),
       password_confirmation: Map.get(params, "password_confirmation", ""),
       trigger_submit: true
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Register</h1>
      <form
        id="live-register-form"
        action="/auth/users/register"
        method="post"
        phx-submit="register"
        phx-trigger-action={@trigger_submit}
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <input type="hidden" name="user[return_to]" value="/auth/live/dashboard" />

        <label for="live_auth_register_email">Email</label>
        <input id="live_auth_register_email" name="user[email]" type="email" value={@email} />

        <label for="live_auth_register_password">Password</label>
        <input id="live_auth_register_password" name="user[password]" type="password" value={@password} />

        <label for="live_auth_register_password_confirmation">Confirm Password</label>
        <input
          id="live_auth_register_password_confirmation"
          name="user[password_confirmation]"
          type="password"
          value={@password_confirmation}
        />

        <button type="submit">Create live account</button>
      </form>
    </main>
    """
  end
end
