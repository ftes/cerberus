defmodule Cerberus.Fixtures.AuthController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Cerberus.Fixtures.AuthStore

  def static_register(conn, _params) do
    conn = Plug.Conn.fetch_session(conn)

    case current_user(conn) do
      {:ok, _user} ->
        redirect(conn, to: "/auth/static/dashboard")

      :error ->
        html(conn, registration_html("/auth/static/dashboard", "Create account"))
    end
  end

  def static_log_in(conn, _params) do
    conn = Plug.Conn.fetch_session(conn)

    case current_user(conn) do
      {:ok, _user} ->
        redirect(conn, to: "/auth/static/dashboard")

      :error ->
        html(conn, log_in_html("/auth/static/dashboard"))
    end
  end

  def static_dashboard(conn, _params) do
    conn = Plug.Conn.fetch_session(conn)

    case current_user(conn) do
      {:ok, user} ->
        html(conn, dashboard_html("Static", user.email, "/auth/static/users/log_in"))

      :error ->
        redirect(conn, to: "/auth/static/users/log_in")
    end
  end

  def register(conn, params) do
    conn = Plug.Conn.fetch_session(conn)
    params = merged_request_params(conn, params)
    user_params = Map.get(params, "user", %{})
    email = Map.get(user_params, "email", "")
    password = Map.get(user_params, "password", "")
    password_confirmation = Map.get(user_params, "password_confirmation", "")
    return_to = Map.get(user_params, "return_to", "/auth/static/dashboard")

    if password == password_confirmation do
      case AuthStore.register_user(email, password) do
        {:ok, user} ->
          conn
          |> Plug.Conn.put_session(:auth_user_id, user.id)
          |> redirect(to: return_to)

        {:error, :email_taken} ->
          conn
          |> put_status(:unprocessable_entity)
          |> html(registration_html(return_to, "Create account", "Email already taken"))

        {:error, :invalid} ->
          conn
          |> put_status(:unprocessable_entity)
          |> html(registration_html(return_to, "Create account", "Email and password are required"))
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> html(registration_html(return_to, "Create account", "Passwords do not match"))
    end
  end

  def log_in(conn, params) do
    conn = Plug.Conn.fetch_session(conn)
    params = merged_request_params(conn, params)
    user_params = Map.get(params, "user", %{})
    email = Map.get(user_params, "email", "")
    password = Map.get(user_params, "password", "")
    return_to = Map.get(user_params, "return_to", "/auth/static/dashboard")

    case AuthStore.authenticate(email, password) do
      {:ok, user} ->
        conn
        |> Plug.Conn.put_session(:auth_user_id, user.id)
        |> redirect(to: return_to)

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unprocessable_entity)
        |> html(log_in_html(return_to, "Invalid email or password"))
    end
  end

  def log_out(conn, params) do
    conn = Plug.Conn.fetch_session(conn)
    params = merged_request_params(conn, params)
    return_to = Map.get(params, "return_to", "/auth/static/users/log_in")

    conn
    |> Plug.Conn.configure_session(drop: true)
    |> redirect(to: return_to)
  end

  defp registration_html(return_to, submit_text, error_message \\ nil) do
    error_block =
      if is_binary(error_message) do
        ~s(<p id="registration-error">#{error_message}</p>)
      else
        ""
      end

    """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Register User</title>
      </head>
      <body>
        <main>
          <h1>Register</h1>
          #{error_block}
          <form action="/auth/users/register" method="post">
            <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
            <input type="hidden" name="user[return_to]" value="#{return_to}" />

            <label for="auth_register_email">Email</label>
            <input id="auth_register_email" name="user[email]" type="email" value="" />

            <label for="auth_register_password">Password</label>
            <input id="auth_register_password" name="user[password]" type="password" value="" />

            <label for="auth_register_password_confirmation">Confirm Password</label>
            <input
              id="auth_register_password_confirmation"
              name="user[password_confirmation]"
              type="password"
              value=""
            />

            <button type="submit">#{submit_text}</button>
          </form>
        </main>
      </body>
    </html>
    """
  end

  defp log_in_html(return_to, error_message \\ nil) do
    error_block =
      if is_binary(error_message) do
        ~s(<p id="log-in-error">#{error_message}</p>)
      else
        ""
      end

    """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Log In User</title>
      </head>
      <body>
        <main>
          <h1>Log in</h1>
          #{error_block}
          <form action="/auth/users/log_in" method="post">
            <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
            <input type="hidden" name="user[return_to]" value="#{return_to}" />

            <label for="auth_log_in_email">Email</label>
            <input id="auth_log_in_email" name="user[email]" type="email" value="" />

            <label for="auth_log_in_password">Password</label>
            <input id="auth_log_in_password" name="user[password]" type="password" value="" />

            <button type="submit">Log in</button>
          </form>
        </main>
      </body>
    </html>
    """
  end

  defp dashboard_html(kind, email, return_to) do
    """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture #{kind} Auth Dashboard</title>
      </head>
      <body>
        <main>
          <h1>#{kind} Auth Dashboard</h1>
          <p>Signed in as: #{email}</p>

          <form action="/auth/users/log_out" method="post">
            <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
            <input type="hidden" name="return_to" value="#{return_to}" />
            <button type="submit">Log out</button>
          </form>
        </main>
      </body>
    </html>
    """
  end

  defp current_user(conn) do
    conn = Plug.Conn.fetch_session(conn)

    conn
    |> Plug.Conn.get_session(:auth_user_id)
    |> AuthStore.get_user()
  end

  defp merged_request_params(conn, params) when is_map(params) do
    conn
    |> Plug.Conn.fetch_query_params()
    |> Map.get(:query_params, %{})
    |> Map.merge(params)
  end
end
