defmodule Cerberus.Assertions do
  @moduledoc false

  alias Cerberus.InvalidLocatorError
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Session
  alias ExUnit.AssertionError

  @spec click(arg, term(), Options.click_opts()) :: arg when arg: var
  def click(session, locator_input, opts \\ []) do
    {locator, opts} = normalize_click_locator(locator_input, opts)
    opts = Options.validate_click!(opts)
    driver = Cerberus.driver_module!(session)

    case driver.click(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("click", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec fill_in(arg, term(), Options.fill_in_value(), Options.fill_in_opts()) :: arg when arg: var
  def fill_in(session, locator_input, value, opts \\ []) when is_list(opts) do
    locator = normalize_fill_in_locator(locator_input)
    opts = Options.validate_fill_in!(opts)
    driver = Cerberus.driver_module!(session)

    case driver.fill_in(session, locator, to_string(value), opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("fill_in", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec submit(arg, term(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator_input, opts \\ []) do
    locator = normalize_submit_locator(locator_input)
    opts = Options.validate_submit!(opts)
    driver = Cerberus.driver_module!(session)

    case driver.submit(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("submit", locator_input, opts, reason, observed, failed_session)
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
          %{driver: driver_kind},
          session
        )
  end

  @spec assert_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def assert_has(session, locator_input, opts \\ []) do
    locator = normalize_assert_locator(locator_input)
    opts = Options.validate_assert!(opts, "assert_has/3")
    driver = Cerberus.driver_module!(session)

    case driver.assert_has(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("assert_has", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec refute_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, locator_input, opts \\ []) do
    locator = normalize_assert_locator(locator_input)
    opts = Options.validate_assert!(opts, "refute_has/3")
    driver = Cerberus.driver_module!(session)

    case driver.refute_has(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("refute_has", locator_input, opts, reason, observed, failed_session)
    end
  end

  defp format_error(op, locator, opts, reason, observed, session) do
    transition = observed_transition(observed) || Session.transition(session)
    scope = Session.scope(session)
    current_path = session |> Session.current_path() |> Path.normalize()

    """
    #{op} failed: #{reason}
    locator: #{inspect(locator)}
    opts: #{inspect(opts)}
    current_path: #{inspect(current_path)}
    scope: #{inspect(scope)}
    transition: #{inspect(transition)}
    observed: #{inspect(observed)}
    """
  end

  defp observed_transition(observed) when is_map(observed) do
    observed[:transition] || observed["transition"]
  end

  defp observed_transition(_observed), do: nil

  defp normalize_click_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)

    case locator do
      %Locator{kind: :text} ->
        {locator, opts}

      %Locator{kind: :label, value: value} ->
        {%Locator{kind: :text, value: value}, opts}

      %Locator{kind: :link, value: value} ->
        {%Locator{kind: :text, value: value}, Keyword.put(opts, :kind, :link)}

      %Locator{kind: :button, value: value} ->
        {%Locator{kind: :text, value: value}, Keyword.put(opts, :kind, :button)}

      %Locator{kind: :testid} ->
        raise InvalidLocatorError, locator: locator_input, message: "testid locators are not yet supported for click/3"
    end
  end

  defp normalize_fill_in_locator(locator_input) do
    locator = Locator.normalize(locator_input)

    case locator do
      %Locator{kind: :text} ->
        locator

      %Locator{kind: :label, value: value} ->
        %Locator{kind: :text, value: value}

      %Locator{kind: :link} ->
        raise InvalidLocatorError, locator: locator_input, message: "link locators are not supported for fill_in/4"

      %Locator{kind: :button} ->
        raise InvalidLocatorError, locator: locator_input, message: "button locators are not supported for fill_in/4"

      %Locator{kind: :testid} ->
        raise InvalidLocatorError, locator: locator_input, message: "testid locators are not yet supported for fill_in/4"
    end
  end

  defp normalize_submit_locator(locator_input) do
    locator = Locator.normalize(locator_input)

    case locator do
      %Locator{kind: :text} ->
        locator

      %Locator{kind: :button, value: value} ->
        %Locator{kind: :text, value: value}

      %Locator{kind: :label} ->
        raise InvalidLocatorError, locator: locator_input, message: "label locators are not supported for submit/3"

      %Locator{kind: :link} ->
        raise InvalidLocatorError, locator: locator_input, message: "link locators are not supported for submit/3"

      %Locator{kind: :testid} ->
        raise InvalidLocatorError, locator: locator_input, message: "testid locators are not yet supported for submit/3"
    end
  end

  defp normalize_assert_locator(locator_input) do
    locator = Locator.normalize(locator_input)

    case locator do
      %Locator{kind: :text} ->
        locator

      %Locator{kind: kind, value: value} when kind in [:label, :link, :button] ->
        %Locator{kind: :text, value: value}

      %Locator{kind: :testid} ->
        raise InvalidLocatorError,
          locator: locator_input,
          message: "testid locators are not yet supported for assert_has/3 or refute_has/3"
    end
  end
end
