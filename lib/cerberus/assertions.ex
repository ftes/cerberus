defmodule Cerberus.Assertions do
  @moduledoc false

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.InvalidLocatorError
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Phoenix.LiveViewTimeout
  alias Cerberus.Session
  alias ExUnit.AssertionError

  @spec click(arg, term(), Options.click_opts()) :: arg when arg: var
  def click(session, locator_input, opts \\ []) do
    {locator, opts} = normalize_click_locator(locator_input, opts)
    opts = Options.validate_click!(opts)
    driver = driver_module_for_session!(session)

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
    {locator, opts} = normalize_fill_in_locator(locator_input, opts)
    opts = Options.validate_fill_in!(opts)
    driver = driver_module_for_session!(session)

    case driver.fill_in(session, locator, to_string(value), opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("fill_in", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec select(arg, term(), Options.select_opts()) :: arg when arg: var
  def select(session, locator_input, opts \\ []) when is_list(opts) do
    {locator, opts} = normalize_select_locator(locator_input, opts)
    opts = Options.validate_select!(opts)
    driver = driver_module_for_session!(session)

    case driver.select(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("select", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec choose(arg, term(), Options.choose_opts()) :: arg when arg: var
  def choose(session, locator_input, opts \\ []) when is_list(opts) do
    {locator, opts} = normalize_choose_locator(locator_input, opts)
    opts = Options.validate_choose!(opts, "choose/3")
    driver = driver_module_for_session!(session)

    case driver.choose(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("choose", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec check(arg, term(), Options.check_opts()) :: arg when arg: var
  def check(session, locator_input, opts \\ []) when is_list(opts) do
    {locator, opts} = normalize_check_locator(locator_input, opts, "check/3")
    opts = Options.validate_check!(opts, "check/3")
    driver = driver_module_for_session!(session)

    case driver.check(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("check", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec uncheck(arg, term(), Options.check_opts()) :: arg when arg: var
  def uncheck(session, locator_input, opts \\ []) when is_list(opts) do
    {locator, opts} = normalize_check_locator(locator_input, opts, "uncheck/3")
    opts = Options.validate_check!(opts, "uncheck/3")
    driver = driver_module_for_session!(session)

    case driver.uncheck(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("uncheck", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec upload(arg, term(), String.t(), Options.upload_opts()) :: arg when arg: var
  def upload(session, locator_input, path, opts \\ [])

  def upload(session, locator_input, path, opts) when is_binary(path) and is_list(opts) do
    ensure_non_empty_upload_path!(path)
    {locator, opts} = normalize_upload_locator(locator_input, opts)
    opts = Options.validate_upload!(opts)
    driver = driver_module_for_session!(session)

    case driver.upload(session, locator, path, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("upload", locator_input, opts, reason, observed, failed_session)
    end
  end

  def upload(_session, _locator_input, _path, _opts) do
    raise ArgumentError, "upload/4 expects a non-empty path string and keyword options"
  end

  @spec submit(arg, term(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator_input, opts \\ []) do
    {locator, opts} = normalize_submit_locator(locator_input, opts)
    opts = Options.validate_submit!(opts)
    driver = driver_module_for_session!(session)

    case driver.submit(session, locator, opts) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("submit", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec unsupported(Session.t(), atom()) :: no_return()
  def unsupported(session, operation), do: unsupported(session, operation, [])

  @spec unsupported(Session.t(), atom(), keyword()) :: no_return()
  def unsupported(session, operation, opts) when is_atom(operation) and is_list(opts) do
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
  def assert_has(session, locator_input, call_opts \\ []) do
    call_has_timeout = Keyword.has_key?(call_opts, :timeout)
    {locator, call_opts} = normalize_assert_locator(locator_input, call_opts)
    validated_opts = Options.validate_assert!(call_opts, "assert_has/3")
    {validated_timeout, driver_opts} = Keyword.pop(validated_opts, :timeout, 0)
    timeout = resolve_assert_timeout(session, call_has_timeout, validated_timeout)
    message_opts = Keyword.put(driver_opts, :timeout, timeout)

    if match?(%BrowserSession{}, session) do
      browser_opts = Keyword.put(driver_opts, :timeout, timeout)
      run_assertion!(session, :assert_has, locator, locator_input, browser_opts, message_opts)
    else
      LiveViewTimeout.with_timeout(session, timeout, fn timed_session ->
        run_assertion!(timed_session, :assert_has, locator, locator_input, driver_opts, message_opts)
      end)
    end
  end

  @spec refute_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, locator_input, call_opts \\ []) do
    call_has_timeout = Keyword.has_key?(call_opts, :timeout)
    {locator, call_opts} = normalize_assert_locator(locator_input, call_opts)
    validated_opts = Options.validate_assert!(call_opts, "refute_has/3")
    {validated_timeout, driver_opts} = Keyword.pop(validated_opts, :timeout, 0)
    timeout = resolve_assert_timeout(session, call_has_timeout, validated_timeout)
    message_opts = Keyword.put(driver_opts, :timeout, timeout)

    if match?(%BrowserSession{}, session) do
      browser_opts = Keyword.put(driver_opts, :timeout, timeout)
      run_assertion!(session, :refute_has, locator, locator_input, browser_opts, message_opts)
    else
      LiveViewTimeout.with_timeout(session, timeout, fn timed_session ->
        run_assertion!(timed_session, :refute_has, locator, locator_input, driver_opts, message_opts)
      end)
    end
  end

  defp run_assertion!(session, op, locator, locator_input, driver_opts, message_opts) do
    driver = driver_module_for_session!(session)

    case apply(driver, op, [session, locator, driver_opts]) do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message:
            format_error(
              Atom.to_string(op),
              locator_input,
              message_opts,
              reason,
              observed,
              failed_session
            )
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

  defp resolve_assert_timeout(_session, true, validated_timeout), do: validated_timeout
  defp resolve_assert_timeout(%LiveSession{} = session, false, _validated_timeout), do: Session.assert_timeout_ms(session)

  defp resolve_assert_timeout(%BrowserSession{} = session, false, _validated_timeout),
    do: Session.assert_timeout_ms(session)

  defp resolve_assert_timeout(_session, false, _validated_timeout), do: 0

  defp driver_module_for_session!(%StaticSession{}), do: StaticSession
  defp driver_module_for_session!(%LiveSession{}), do: LiveSession
  defp driver_module_for_session!(%BrowserSession{}), do: BrowserSession

  defp driver_module_for_session!(session) do
    raise ArgumentError,
          "unsupported session #{inspect(session)}; expected a Cerberus session"
  end

  defp normalize_click_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)
    opts = merge_locator_selector_opts(locator, opts)
    normalize_click_locator_kind(locator, locator_input, opts)
  end

  defp normalize_click_locator_kind(%Locator{kind: :text} = locator, _locator_input, opts), do: {locator, opts}

  defp normalize_click_locator_kind(%Locator{kind: :label}, locator_input, _opts) do
    raise InvalidLocatorError,
      locator: locator_input,
      message:
        "label locators target form-field lookup and are not supported for click/3; use text(...) for generic element text matching"
  end

  defp normalize_click_locator_kind(%Locator{kind: :link, value: value} = locator, _locator_input, opts) do
    normalized = %{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :link)}
    {normalized, Keyword.put(opts, :kind, :link)}
  end

  defp normalize_click_locator_kind(%Locator{kind: :button, value: value} = locator, _locator_input, opts) do
    normalized = %{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :button)}
    {normalized, Keyword.put(opts, :kind, :button)}
  end

  defp normalize_click_locator_kind(%Locator{kind: :title, value: value} = locator, _locator_input, opts) do
    {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :title)}, opts}
  end

  defp normalize_click_locator_kind(%Locator{kind: :alt, value: value} = locator, _locator_input, opts) do
    {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :alt)}, opts}
  end

  defp normalize_click_locator_kind(%Locator{kind: :css, value: selector} = locator, _locator_input, opts) do
    updated_locator = %{locator | kind: :text, value: "", opts: Keyword.put(locator.opts, :selector, selector)}
    {updated_locator, Keyword.put(opts, :selector, selector)}
  end

  defp normalize_click_locator_kind(%Locator{kind: :placeholder}, locator_input, _opts) do
    raise InvalidLocatorError, locator: locator_input, message: "placeholder locators are not supported for click/3"
  end

  defp normalize_click_locator_kind(%Locator{kind: :testid, value: value} = locator, _locator_input, opts) do
    normalized_opts = locator.opts |> put_match_by(:testid) |> ensure_exact_opt(true)
    {%{locator | kind: :text, value: value, opts: normalized_opts}, opts}
  end

  defp normalize_fill_in_locator(locator_input, opts) do
    normalize_labeled_field_locator(
      locator_input,
      opts,
      "fill_in/4",
      "text locators are not supported for fill_in/4; use a plain string/regex label shorthand or label(...), role(:textbox, ...), or css(...)"
    )
  end

  defp normalize_upload_locator(locator_input, opts) do
    normalize_labeled_field_locator(
      locator_input,
      opts,
      "upload/4",
      "text locators are not supported for upload/4; use a plain string/regex label shorthand or label(...), role(:textbox, ...), or css(...)"
    )
  end

  defp normalize_check_locator(locator_input, opts, op_name) do
    normalize_labeled_field_locator(
      locator_input,
      opts,
      op_name,
      "text locators are not supported for #{op_name}; use a plain string/regex label shorthand or label(...) or css(...)"
    )
  end

  defp normalize_select_locator(locator_input, opts) do
    normalize_labeled_field_locator(
      locator_input,
      opts,
      "select/3",
      "text locators are not supported for select/3; use a plain string/regex label shorthand or label(...), role(:combobox, ...), or css(...)"
    )
  end

  defp normalize_labeled_field_locator(locator_input, opts, op_name, text_error_message) do
    locator = Locator.normalize(locator_input)
    opts = merge_locator_selector_opts(locator, opts)
    normalize_labeled_field_kind(locator, locator_input, opts, op_name, text_error_message)
  end

  defp normalize_labeled_field_kind(
         %Locator{kind: :text, value: value},
         locator_input,
         opts,
         _op_name,
         text_error_message
       ) do
    if label_shorthand?(locator_input) do
      {%Locator{kind: :label, value: value}, opts}
    else
      raise InvalidLocatorError, locator: locator_input, message: text_error_message
    end
  end

  defp normalize_labeled_field_kind(
         %Locator{kind: :label, value: value},
         _locator_input,
         opts,
         _op_name,
         _text_error_message
       ) do
    {%Locator{kind: :label, value: value}, opts}
  end

  defp normalize_labeled_field_kind(
         %Locator{kind: kind, value: value} = locator,
         _locator_input,
         opts,
         _op_name,
         _text_error_message
       )
       when kind in [:placeholder, :title] do
    normalized_opts = put_match_by(locator.opts, kind)
    {%Locator{kind: :label, value: value, opts: normalized_opts}, opts}
  end

  defp normalize_labeled_field_kind(
         %Locator{kind: :testid, value: value} = locator,
         _locator_input,
         opts,
         _op_name,
         _text_error_message
       ) do
    normalized_opts = locator.opts |> put_match_by(:testid) |> ensure_exact_opt(true)
    {%Locator{kind: :label, value: value, opts: normalized_opts}, opts}
  end

  defp normalize_labeled_field_kind(
         %Locator{kind: :css, value: selector} = locator,
         _locator_input,
         opts,
         _op_name,
         _text_error_message
       ) do
    updated_locator = %{locator | kind: :label, value: "", opts: Keyword.put(locator.opts, :selector, selector)}
    {updated_locator, Keyword.put(opts, :selector, selector)}
  end

  defp normalize_labeled_field_kind(%Locator{kind: kind}, locator_input, _opts, op_name, _text_error_message)
       when kind in [:link, :button, :alt] do
    raise InvalidLocatorError, locator: locator_input, message: "#{kind} locators are not supported for #{op_name}"
  end

  defp normalize_choose_locator(locator_input, opts) do
    normalize_check_locator(locator_input, opts, "choose/3")
  end

  defp normalize_assert_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)
    ensure_assert_locator_opts!(locator, locator_input)
    normalize_assert_locator_kind(locator, locator_input, opts)
  end

  defp normalize_assert_locator_kind(%Locator{kind: :text} = locator, _locator_input, opts), do: {locator, opts}

  defp normalize_assert_locator_kind(%Locator{kind: :css}, locator_input, _opts) do
    raise InvalidLocatorError,
      locator: locator_input,
      message: "css locators are not supported for assert_has/3 or refute_has/3 in this slice"
  end

  defp normalize_assert_locator_kind(%Locator{kind: kind, value: value} = locator, _locator_input, opts)
       when kind in [:label, :link, :button, :placeholder, :title, :alt] do
    {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, kind)}, opts}
  end

  defp normalize_assert_locator_kind(%Locator{kind: :testid, value: value} = locator, _locator_input, opts) do
    normalized_opts = locator.opts |> put_match_by(:testid) |> ensure_exact_opt(true)
    {%{locator | kind: :text, value: value, opts: normalized_opts}, opts}
  end

  defp normalize_submit_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)
    opts = merge_locator_selector_opts(locator, opts)

    case locator do
      %Locator{kind: :text} ->
        {locator, opts}

      %Locator{kind: :button, value: value} ->
        {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :button)}, opts}

      %Locator{kind: :title, value: value} ->
        {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :title)}, opts}

      %Locator{kind: :alt, value: value} ->
        {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, :alt)}, opts}

      %Locator{kind: :testid, value: value} ->
        normalized_opts = locator.opts |> put_match_by(:testid) |> ensure_exact_opt(true)
        {%{locator | kind: :text, value: value, opts: normalized_opts}, opts}

      %Locator{kind: :css, value: selector} ->
        updated_locator = %{locator | kind: :text, value: "", opts: Keyword.put(locator.opts, :selector, selector)}
        {updated_locator, Keyword.put(opts, :selector, selector)}

      %Locator{kind: :label} ->
        raise InvalidLocatorError, locator: locator_input, message: "label locators are not supported for submit/3"

      %Locator{kind: :link} ->
        raise InvalidLocatorError, locator: locator_input, message: "link locators are not supported for submit/3"
    end
  end

  defp ensure_assert_locator_opts!(%Locator{opts: locator_opts}, locator_input) do
    if Keyword.has_key?(locator_opts, :selector) do
      raise InvalidLocatorError,
        locator: locator_input,
        message: "selector locator option is not supported for assert_has/3 or refute_has/3 in this slice"
    end

    if Keyword.has_key?(locator_opts, :has) do
      raise InvalidLocatorError,
        locator: locator_input,
        message: "has locator option is not supported for assert_has/3 or refute_has/3 in this slice"
    end
  end

  defp merge_locator_selector_opts(%Locator{opts: locator_opts}, opts) when is_list(locator_opts) do
    selector_opt = Keyword.take(locator_opts, [:selector])
    Keyword.merge(selector_opt, opts)
  end

  defp label_shorthand?(locator_input) do
    is_binary(locator_input) or is_struct(locator_input, Regex)
  end

  defp put_match_by(opts, value) when is_list(opts) do
    Keyword.put(opts, :match_by, value)
  end

  defp ensure_exact_opt(opts, default) when is_list(opts) and is_boolean(default) do
    if Keyword.has_key?(opts, :exact) do
      opts
    else
      Keyword.put(opts, :exact, default)
    end
  end

  defp ensure_non_empty_upload_path!(path) do
    if String.trim(path) == "" do
      raise ArgumentError, "upload/4 expects a non-empty path string"
    end
  end
end
