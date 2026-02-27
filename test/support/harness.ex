defmodule Cerberus.Harness do
  @moduledoc """
  ExUnit-friendly helpers for running one scenario across multiple Cerberus drivers.

  Conformance policy (ADR-0003):
  - for designated conformance suites, browser results are the oracle
    when comparing static/live behavior.

  v0 keeps the execution model intentionally small:
  - choose drivers from `context[:drivers]` tags (or defaults),
  - execute the same scenario for each driver,
  - return normalized result maps for reporting and assertions.
  """

  alias Cerberus.Session
  alias ExUnit.AssertionError

  @default_drivers [:static, :live, :browser]

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

    drivers
    |> Enum.map(&run_driver(&1, session_opts, scenario))
    |> sort_results()
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
    session = Cerberus.session(driver, session_opts)

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

  defp normalize_value(%Session{} = session) do
    %{
      value: session,
      session_data: %{
        operation: session.last_result && session.last_result[:op],
        current_path: session.current_path,
        observed: session.last_result && session.last_result[:observed]
      }
    }
  end

  defp normalize_value(value) do
    %{value: value, session_data: %{}}
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
end
