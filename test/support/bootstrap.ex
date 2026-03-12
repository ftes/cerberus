defmodule Cerberus.TestSupport.Bootstrap do
  @moduledoc false

  alias Cerberus.Fixtures.Endpoint
  alias Cerberus.Fixtures.Repo
  alias Ecto.Adapters.SQL

  @sandbox_messages_lock 220_986_421
  @test_support_supervisor Cerberus.TestSupportSupervisor

  @spec start!() :: :ok
  def start! do
    configure_browser!()
    ensure_postgres_database!(Repo.config())
    start_support_supervisor!()
    reset_sandbox_messages!()

    SQL.Sandbox.mode(Repo, :manual)

    {:ok, _} = Endpoint.start_link()
    :ok
  end

  @spec stop!() :: :ok
  def stop! do
    if Cerberus.Profiling.enabled?() do
      Cerberus.Profiling.dump_summary()
    end

    case Process.whereis(@test_support_supervisor) do
      pid when is_pid(pid) ->
        _ = Supervisor.stop(pid, :normal, 15_000)
        :ok

      _ ->
        :ok
    end
  end

  @spec ensure_postgres_database!(keyword()) :: :ok
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

      if not exists? do
        Postgrex.query!(pid, "CREATE DATABASE " <> quote_ident!(database), [])
      end
    rescue
      error in Postgrex.Error ->
        case error.postgres do
          %{code: :duplicate_database} -> :ok
          _ -> reraise(error, __STACKTRACE__)
        end
    after
      GenServer.stop(pid)
    end

    :ok
  end

  defp quote_ident!(value) when is_binary(value) do
    if String.match?(value, ~r/^[A-Za-z0-9_]+$/) do
      ~s("#{value}")
    else
      raise ArgumentError,
            "unsupported PostgreSQL identifier #{inspect(value)}; use alphanumeric + underscore only"
    end
  end

  defp start_support_supervisor! do
    {:ok, _} =
      Supervisor.start_link(
        [
          Repo,
          {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
          Cerberus.Driver.Browser.Supervisor
        ],
        strategy: :one_for_one,
        name: @test_support_supervisor
      )

    :ok
  end

  defp reset_sandbox_messages! do
    SQL.query!(Repo, "SELECT pg_advisory_lock($1)", [@sandbox_messages_lock])

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
      SQL.query!(Repo, "SELECT pg_advisory_unlock($1)", [@sandbox_messages_lock])
    end
  end

  defp configure_browser! do
    browser_name = browser_name_env()
    browser_webdriver_url = browser_webdriver_url(browser_name)

    browser_overrides =
      Enum.reject(
        browser_runtime_overrides(browser_name, browser_webdriver_url),
        fn {_key, value} -> is_nil(value) end
      )

    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(browser_overrides)
    |> then(&Application.put_env(:cerberus, :browser, &1))
  end

  defp browser_runtime_overrides(:chrome, chrome_webdriver_url) do
    [
      browser_name: :chrome,
      headless: boolean_env("HEADLESS"),
      slow_mo: non_neg_integer_env("SLOW_MO"),
      chrome_args: ["--disable-setuid-sandbox", "--disable-dev-shm-usage"],
      chrome_webdriver_url: chrome_webdriver_url,
      webdriver_url: chrome_webdriver_url || non_empty_env("WEBDRIVER_URL"),
      chrome_binary: System.fetch_env!("CHROME"),
      chromedriver_binary: System.fetch_env!("CHROMEDRIVER")
    ]
  end

  defp browser_runtime_overrides(:firefox, firefox_webdriver_url) do
    [
      browser_name: :firefox,
      headless: boolean_env("HEADLESS"),
      slow_mo: non_neg_integer_env("SLOW_MO"),
      firefox_webdriver_url: firefox_webdriver_url,
      webdriver_url: firefox_webdriver_url || non_empty_env("WEBDRIVER_URL"),
      firefox_binary: System.fetch_env!("FIREFOX")
    ]
  end

  defp browser_name_env do
    case System.get_env("CERBERUS_BROWSER_NAME") do
      nil -> :chrome
      value -> parse_browser_name!(value)
    end
  end

  defp parse_browser_name!(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "chrome" -> :chrome
      "firefox" -> :firefox
      other -> raise ArgumentError, "unsupported CERBERUS_BROWSER_NAME #{inspect(other)}"
    end
  end

  defp browser_webdriver_url(:chrome), do: non_empty_env("WEBDRIVER_URL_CHROME")
  defp browser_webdriver_url(:firefox), do: non_empty_env("WEBDRIVER_URL_FIREFOX")

  defp non_empty_env(key) do
    case System.get_env(key) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end

  defp falsy_env?(value) when value in ["0", "false", "no", "off"], do: true
  defp falsy_env?(_value), do: false

  defp boolean_env(key) do
    case System.get_env(key) do
      nil ->
        nil

      value when is_binary(value) ->
        normalized = value |> String.trim() |> String.downcase()
        not falsy_env?(normalized)
    end
  end

  defp non_neg_integer_env(key) do
    case System.get_env(key) do
      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {number, ""} when number >= 0 -> number
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
