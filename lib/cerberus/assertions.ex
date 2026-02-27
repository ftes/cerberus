defmodule Cerberus.Assertions do
  @moduledoc false

  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Session
  alias ExUnit.AssertionError

  @spec click(arg, term(), Options.click_opts()) :: arg when arg: var
  def click(session, locator_input, opts \\ []) do
    opts = Options.validate_click!(opts)
    locator = Locator.normalize(locator_input)
    driver = Cerberus.driver_module!(session)

    case driver.click(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("click", locator_input, opts, reason, observed)
    end
  end

  @spec fill_in(arg, term(), Options.fill_in_value(), Options.fill_in_opts()) :: arg when arg: var
  def fill_in(session, locator_input, value, opts \\ []) when is_list(opts) do
    opts = Options.validate_fill_in!(opts)
    locator = Locator.normalize(locator_input)
    driver = Cerberus.driver_module!(session)

    case driver.fill_in(session, locator, to_string(value), opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("fill_in", locator_input, opts, reason, observed)
    end
  end

  @spec submit(arg, term(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator_input, opts \\ []) do
    opts = Options.validate_submit!(opts)
    locator = Locator.normalize(locator_input)
    driver = Cerberus.driver_module!(session)

    case driver.submit(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("submit", locator_input, opts, reason, observed)
    end
  end

  @spec unsupported(arg, atom(), keyword()) :: arg when arg: var
  def unsupported(session, operation, opts \\ []) when is_atom(operation) do
    driver_kind = Session.driver_kind(session)

    raise AssertionError,
      message:
        format_error(
          Atom.to_string(operation),
          :none,
          opts,
          "#{operation} is not implemented for #{inspect(driver_kind)} driver in this slice",
          %{driver: driver_kind}
        )
  end

  @spec assert_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def assert_has(session, locator_input, opts \\ []) do
    opts = Options.validate_assert!(opts, "assert_has/3")
    locator = Locator.normalize(locator_input)
    driver = Cerberus.driver_module!(session)

    case driver.assert_has(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, _session, observed, reason} ->
        raise AssertionError,
          message: format_error("assert_has", locator_input, opts, reason, observed)
    end
  end

  @spec refute_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, locator_input, opts \\ []) do
    opts = Options.validate_assert!(opts, "refute_has/3")
    locator = Locator.normalize(locator_input)
    driver = Cerberus.driver_module!(session)

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
end
