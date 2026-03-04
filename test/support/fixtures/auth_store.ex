defmodule Cerberus.Fixtures.AuthStore do
  @moduledoc false

  use Agent

  @type user :: %{
          id: pos_integer(),
          email: String.t(),
          password_hash: String.t()
        }

  @initial_state %{
    next_id: 1,
    users_by_id: %{},
    user_ids_by_email: %{}
  }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts) do
    Agent.start_link(fn -> @initial_state end, name: __MODULE__)
  end

  @spec reset!() :: :ok
  def reset! do
    Agent.update(__MODULE__, fn _ -> @initial_state end)
  end

  @spec register_user(String.t(), String.t()) :: {:ok, user()} | {:error, :invalid | :email_taken}
  def register_user(email, password) when is_binary(email) and is_binary(password) do
    normalized_email = normalize_email(email)

    cond do
      normalized_email == "" ->
        {:error, :invalid}

      password == "" ->
        {:error, :invalid}

      true ->
        Agent.get_and_update(__MODULE__, fn state ->
          case Map.fetch(state.user_ids_by_email, normalized_email) do
            {:ok, _id} ->
              {{:error, :email_taken}, state}

            :error ->
              user = %{
                id: state.next_id,
                email: normalized_email,
                password_hash: hash_password(password)
              }

              updated_state = %{
                next_id: state.next_id + 1,
                users_by_id: Map.put(state.users_by_id, user.id, user),
                user_ids_by_email: Map.put(state.user_ids_by_email, normalized_email, user.id)
              }

              {{:ok, user}, updated_state}
          end
        end)
    end
  end

  @spec authenticate(String.t(), String.t()) :: {:ok, user()} | {:error, :invalid_credentials}
  def authenticate(email, password) when is_binary(email) and is_binary(password) do
    normalized_email = normalize_email(email)

    with {:ok, user} <- get_user_by_email(normalized_email),
         true <- user.password_hash == hash_password(password) do
      {:ok, user}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  @spec get_user(integer() | String.t()) :: {:ok, user()} | :error
  def get_user(id) when is_integer(id) do
    Agent.get(__MODULE__, fn state ->
      case Map.fetch(state.users_by_id, id) do
        {:ok, user} -> {:ok, user}
        :error -> :error
      end
    end)
  end

  def get_user(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed_id, ""} -> get_user(parsed_id)
      _ -> :error
    end
  end

  def get_user(_id), do: :error

  defp get_user_by_email(email) do
    Agent.get(__MODULE__, fn state ->
      with {:ok, user_id} <- Map.fetch(state.user_ids_by_email, email),
           {:ok, user} <- Map.fetch(state.users_by_id, user_id) do
        {:ok, user}
      else
        _ -> :error
      end
    end)
  end

  defp normalize_email(email) do
    email
    |> String.trim()
    |> String.downcase()
  end

  defp hash_password(password) do
    password
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
