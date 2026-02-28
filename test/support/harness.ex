defmodule Cerberus.Harness do
  @moduledoc """
  ExUnit-friendly helpers for running one scenario across multiple Cerberus drivers.

  Conformance policy (ADR-0003):
  - for designated conformance suites, browser results are the oracle
    when comparing static/live behavior.

  v0 keeps the execution model intentionally small:
  - choose drivers from `context[:drivers]` tags (or defaults),
  - optionally merge `context[:session_opts]` into all sessions,
  - optionally merge browser-only overrides from `context[:browser]` (keyword form)
    and `context[:browser_session_opts]`,
  - execute the same scenario for each driver,
  - return normalized result maps for reporting and assertions.
  """

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Session
  alias Ecto.Adapters.SQL.Sandbox
  alias ExUnit.AssertionError
  alias Phoenix.Ecto.SQL.Sandbox, as: PhoenixSandbox

  @default_drivers [:auto, :browser]

  @type driver_kind :: Session.driver_kind()

  @type result ::
          %{
            driver: driver_kind(),
            status: :ok | :error,
            operation: atom() | nil,
            current_path: String.t() | nil,
            observed: map() | nil,
            value: term() | nil,
            error: Exception.t() | nil,
            stacktrace: list(),
            message: String.t() | nil
          }

  @spec drivers(map()) :: [driver_kind()]
  def drivers(context \\ %{})

  def drivers(%{} = context) do
    Map.get(context, :drivers, @default_drivers)
  end

  @spec run(map(), (Session.t() -> term()), keyword()) :: [result()]
  def run(%{} = context, scenario, opts \\ []) when is_function(scenario, 1) do
    reject_driver_override!(opts)

    drivers =
      context
      |> drivers()
      |> normalize_drivers!()

    session_opts = Keyword.get(opts, :session_opts, [])
    sandbox_repos = normalize_sandbox_repos(Keyword.get(opts, :sandbox, false))

    {session_opts, stop_sandbox_owner} =
      maybe_start_sandbox_owner(context, session_opts, sandbox_repos)

    try do
      drivers
      |> Enum.map(&run_driver(&1, session_opts_for_driver(&1, context, session_opts), scenario))
      |> sort_results()
    after
      stop_sandbox_owner.()
    end
  end

  @spec run!(map(), (Session.t() -> Session.t()), keyword()) :: [result()]
  def run!(%{} = context, scenario, opts \\ []) when is_function(scenario, 1) do
    results = run(context, scenario, opts)

    failures = Enum.filter(results, &(&1.status == :error))

    if failures == [] do
      results
    else
      raise AssertionError, message: format_failures(failures)
    end
  end

  @spec sort_results([result()]) :: [result()]
  def sort_results(results) when is_list(results) do
    Enum.sort_by(results, fn result ->
      operation = Map.get(result, :operation) || :unknown
      {operation, result.driver}
    end)
  end

  defp run_driver(driver, session_opts, scenario) do
    session = Cerberus.session_for_driver(driver, session_opts)

    try do
      value = scenario.(session)
      normalized = normalize_value(value)

      Map.merge(
        %{
          driver: driver,
          status: :ok,
          operation: nil,
          current_path: nil,
          observed: nil,
          value: normalized.value,
          error: nil,
          stacktrace: [],
          message: nil
        },
        normalized.session_data
      )
    rescue
      error ->
        %{
          driver: driver,
          status: :error,
          operation: nil,
          current_path: nil,
          observed: nil,
          value: nil,
          error: error,
          stacktrace: __STACKTRACE__,
          message: Exception.message(error)
        }
    end
  end

  defp normalize_value(%StaticSession{} = session) do
    normalize_session_value(session)
  end

  defp normalize_value(%LiveSession{} = session) do
    normalize_session_value(session)
  end

  defp normalize_value(%BrowserSession{} = session) do
    normalize_session_value(session)
  end

  defp normalize_value(value) do
    %{value: value, session_data: %{}}
  end

  defp normalize_session_value(session) do
    last_result = Session.last_result(session)

    %{
      value: session,
      session_data: %{
        operation: last_result && last_result[:op],
        current_path: Session.current_path(session),
        observed: last_result && last_result[:observed]
      }
    }
  end

  defp normalize_drivers!(drivers) when is_list(drivers) do
    Enum.map(drivers, fn driver ->
      Cerberus.driver_module!(driver)
      driver
    end)
  end

  defp reject_driver_override!(opts) do
    if Keyword.has_key?(opts, :drivers) do
      raise ArgumentError,
            "Harness.run/run! no longer supports :drivers opt; use @tag/@moduletag drivers in ExUnit context"
    end
  end

  defp format_failures(failures) do
    lines =
      Enum.map_join(failures, "\n", fn failure ->
        "[#{failure.driver}] #{failure.message || "scenario failed"}"
      end)

    "driver conformance failures:\n" <> lines
  end

  @doc false
  @spec session_opts_for_driver(driver_kind(), map(), keyword()) :: keyword()
  def session_opts_for_driver(driver, context, session_opts \\ [])

  def session_opts_for_driver(:browser, context, session_opts) when is_map(context) and is_list(session_opts) do
    session_opts
    |> merge_session_opts(context_session_opts(context))
    |> merge_session_opts(browser_tag_opts(context))
    |> merge_session_opts(browser_session_opts(context))
  end

  def session_opts_for_driver(_driver, context, session_opts) when is_map(context) and is_list(session_opts) do
    merge_session_opts(session_opts, context_session_opts(context))
  end

  defp normalize_sandbox_repos(false), do: []
  defp normalize_sandbox_repos(nil), do: []

  defp normalize_sandbox_repos(true) do
    Application.get_env(:cerberus, :ecto_repos, [])
  end

  defp normalize_sandbox_repos(repo) when is_atom(repo), do: [repo]
  defp normalize_sandbox_repos(repos) when is_list(repos), do: repos

  defp maybe_start_sandbox_owner(_context, session_opts, []), do: {session_opts, fn -> :ok end}

  defp maybe_start_sandbox_owner(context, session_opts, repos) do
    if repos == [] do
      raise ArgumentError, "Harness.run/run! :sandbox requested but no repos are configured"
    end

    repo =
      case repos do
        [repo] -> repo
        _ -> raise ArgumentError, "Harness.run/run! :sandbox currently expects exactly one repo"
      end

    owner_pid = Sandbox.start_owner!(repo, shared: !Map.get(context, :async, false))

    metadata_header =
      repo
      |> PhoenixSandbox.metadata_for(owner_pid)
      |> PhoenixSandbox.encode_metadata()

    session_opts =
      session_opts
      |> with_sandbox_conn(metadata_header)
      |> Keyword.put(:sandbox_metadata, metadata_header)

    stop_owner = fn ->
      Sandbox.stop_owner(owner_pid)
    end

    {session_opts, stop_owner}
  end

  defp with_sandbox_conn(session_opts, metadata_header) do
    conn =
      case Keyword.get(session_opts, :conn) do
        nil ->
          Phoenix.ConnTest.build_conn()

        %Plug.Conn{} = conn ->
          conn

        other ->
          raise ArgumentError, "expected :conn option to be a Plug.Conn, got: #{inspect(other)}"
      end

    conn =
      conn
      |> Plug.Conn.delete_req_header("user-agent")
      |> Plug.Conn.put_req_header("user-agent", metadata_header)

    Keyword.put(session_opts, :conn, conn)
  end

  defp context_session_opts(context) do
    keyword_context_opt(context, :session_opts, "Harness.run/run! context :session_opts must be a keyword list")
  end

  defp browser_session_opts(context) do
    keyword_context_opt(
      context,
      :browser_session_opts,
      "Harness.run/run! context :browser_session_opts must be a keyword list"
    )
  end

  defp browser_tag_opts(context) do
    case Map.get(context, :browser) do
      nil ->
        []

      true ->
        []

      false ->
        []

      browser_opts when is_list(browser_opts) ->
        if Keyword.keyword?(browser_opts) do
          [browser: browser_opts]
        else
          invalid_browser_tag!(browser_opts)
        end

      other ->
        invalid_browser_tag!(other)
    end
  end

  defp keyword_context_opt(context, key, error_message) do
    case Map.get(context, key) do
      nil ->
        []

      value when is_list(value) ->
        if Keyword.keyword?(value) do
          value
        else
          raise ArgumentError, "#{error_message}, got: #{inspect(value)}"
        end

      other ->
        raise ArgumentError, "#{error_message}, got: #{inspect(other)}"
    end
  end

  defp merge_session_opts(base, overrides) when is_list(base) and is_list(overrides) do
    merged =
      base
      |> Keyword.delete(:browser)
      |> Keyword.merge(Keyword.delete(overrides, :browser))

    browser_opts =
      base
      |> Keyword.get(:browser, [])
      |> merge_browser_opts(Keyword.get(overrides, :browser, []))

    if browser_opts == [] do
      merged
    else
      Keyword.put(merged, :browser, browser_opts)
    end
  end

  defp merge_browser_opts(base, overrides) when is_list(base) and is_list(overrides) do
    if Keyword.keyword?(base) and Keyword.keyword?(overrides) do
      Keyword.merge(base, overrides)
    else
      raise ArgumentError,
            "Harness.run/run! browser opts must be keyword lists, got base=#{inspect(base)} override=#{inspect(overrides)}"
    end
  end

  defp merge_browser_opts(base, overrides) do
    raise ArgumentError,
          "Harness.run/run! browser opts must be keyword lists, got base=#{inspect(base)} override=#{inspect(overrides)}"
  end

  defp invalid_browser_tag!(value) do
    raise ArgumentError,
          "Harness.run/run! context :browser must be true/false or a keyword list of browser opts, got: #{inspect(value)}"
  end
end
