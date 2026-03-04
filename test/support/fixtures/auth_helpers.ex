defmodule Cerberus.Fixtures.AuthHelpers do
  @moduledoc false

  alias Cerberus.Fixtures.AuthStore

  @spec current_user_from_session(map()) :: {:ok, AuthStore.user()} | :error
  def current_user_from_session(session) when is_map(session) do
    session
    |> session_user_id()
    |> AuthStore.get_user()
  end

  defp session_user_id(session) do
    Map.get(session, "auth_user_id") || Map.get(session, :auth_user_id)
  end
end
