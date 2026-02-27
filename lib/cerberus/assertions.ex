defmodule Cerberus.Assertions do
  @moduledoc false

  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Session
  alias ExUnit.AssertionError

  @spec click(Session.t(), term(), Options.click_opts()) :: Session.t()
  def click(%Session{} = session, locator_input, opts \\ []) do
    opts = Options.validate_click!(opts)
    locator = Locator.normalize(locator_input)
    driver = driver_module!(session.driver)

    case driver.click(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("click", locator_input, opts, reason, observed)
    end
  end

  @spec fill_in(Session.t(), term(), Options.fill_in_value(), Options.fill_in_opts()) ::
          Session.t()
  def fill_in(%Session{} = session, locator_input, value, opts \\ []) when is_list(opts) do
    opts = Options.validate_fill_in!(opts)
    locator = Locator.normalize(locator_input)
    driver = driver_module!(session.driver)

    case driver.fill_in(session, locator, to_string(value), opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("fill_in", locator_input, opts, reason, observed)
    end
  end

  @spec submit(Session.t(), term(), Options.submit_opts()) :: Session.t()
  def submit(%Session{} = session, locator_input, opts \\ []) do
    opts = Options.validate_submit!(opts)
    locator = Locator.normalize(locator_input)
    driver = driver_module!(session.driver)

    case driver.submit(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("submit", locator_input, opts, reason, observed)
    end
  end

  @spec unsupported(Session.t(), atom(), keyword()) :: Session.t()
  def unsupported(%Session{} = session, operation, opts \\ []) when is_atom(operation) do
    raise AssertionError,
      message:
        format_error(
          Atom.to_string(operation),
          :none,
          opts,
          "#{operation} is not implemented for #{inspect(session.driver)} driver in this slice",
          %{driver: session.driver}
        )
  end

  @spec assert_has(Session.t(), term(), Options.assert_opts()) :: Session.t()
  def assert_has(%Session{} = session, locator_input, opts \\ []) do
    opts = Options.validate_assert!(opts, "assert_has/3")
    locator = Locator.normalize(locator_input)
    driver = driver_module!(session.driver)

    case driver.assert_has(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("assert_has", locator_input, opts, reason, observed)
    end
  end

  @spec refute_has(Session.t(), term(), Options.assert_opts()) :: Session.t()
  def refute_has(%Session{} = session, locator_input, opts \\ []) do
    opts = Options.validate_assert!(opts, "refute_has/3")
    locator = Locator.normalize(locator_input)
    driver = driver_module!(session.driver)

    case driver.refute_has(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("refute_has", locator_input, opts, reason, observed)
    end
  end

  defp format_error(op, locator, opts, reason, observed) do
    """
    #{op} failed: #{reason}
    locator: #{inspect(locator)}
    opts: #{inspect(opts)}
    observed: #{inspect(observed)}
    """
  end

  defp driver_module!(:static), do: Cerberus.Driver.Static
  defp driver_module!(:live), do: Cerberus.Driver.Live
  defp driver_module!(:browser), do: Cerberus.Driver.Browser
end
