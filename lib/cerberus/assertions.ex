defmodule Cerberus.Assertions do
  @moduledoc false

  alias ExUnit.AssertionError

  alias Cerberus.Locator
  alias Cerberus.Session

  @spec click(Session.t(), term(), keyword()) :: Session.t()
  def click(%Session{} = session, locator_input, opts \\ []) do
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

  @spec assert_has(Session.t(), term(), keyword()) :: Session.t()
  def assert_has(%Session{} = session, locator_input, opts \\ []) do
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

  @spec refute_has(Session.t(), term(), keyword()) :: Session.t()
  def refute_has(%Session{} = session, locator_input, opts \\ []) do
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
