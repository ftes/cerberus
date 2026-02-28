alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo
alias Ecto.Adapters.SQL

defmodule Cerberus.TestHelperSupport do
  @moduledoc false

  def ensure_postgres_database!(repo_config) do
    database = Keyword.fetch!(repo_config, :database)
    maintenance_database = Keyword.get(repo_config, :maintenance_database, "postgres")

    admin_opts =
      repo_config
      |> Keyword.take([:hostname, :port, :username, :password, :ssl, :socket_options])
      |> Keyword.put(:database, maintenance_database)
      |> Keyword.put(:backoff_type, :stop)

    {:ok, pid} = Postgrex.start_link(admin_opts)

    try do
      exists? =
        case Postgrex.query!(pid, "SELECT 1 FROM pg_database WHERE datname = $1", [database]) do
          %{num_rows: count} when count > 0 -> true
          _ -> false
        end

      if !exists? do
        create_database!(pid, database)
      end
    after
      GenServer.stop(pid)
    end
  end

  defp create_database!(pid, database) do
    Postgrex.query!(pid, "CREATE DATABASE " <> quote_ident!(database), [])
  rescue
    error in Postgrex.Error ->
      case error.postgres do
        %{code: :duplicate_database} -> :ok
        _ -> reraise(error, __STACKTRACE__)
      end
  end

  defp quote_ident!(value) when is_binary(value) do
    if String.match?(value, ~r/^[A-Za-z0-9_]+$/) do
      ~s("#{value}")
    else
      raise ArgumentError,
            "unsupported PostgreSQL identifier #{inspect(value)}; use alphanumeric + underscore only"
    end
  end
end

ExUnit.start()

Cerberus.TestHelperSupport.ensure_postgres_database!(Repo.config())

{:ok, _} =
  Supervisor.start_link(
    [
      Repo,
      {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
      Cerberus.Driver.Browser.Supervisor
    ],
    strategy: :one_for_one
  )

SQL.query!(
  Repo,
  "SELECT pg_advisory_lock($1)",
  [220_986_421]
)

try do
  SQL.query!(
    Repo,
    """
    CREATE TABLE IF NOT EXISTS sandbox_messages (
      id BIGSERIAL PRIMARY KEY,
      body TEXT NOT NULL,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """,
    []
  )

  SQL.query!(Repo, "TRUNCATE TABLE sandbox_messages RESTART IDENTITY", [])
after
  SQL.query!(Repo, "SELECT pg_advisory_unlock($1)", [220_986_421])
end

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)

{:ok, _} = Endpoint.start_link()

base_url =
  case System.get_env("CERBERUS_BASE_URL_HOST") do
    nil ->
      Endpoint.url()

    host ->
      uri = URI.parse(Endpoint.url())
      URI.to_string(%{uri | host: host})
  end

Application.put_env(:cerberus, :base_url, base_url)
