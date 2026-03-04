defmodule Cerberus.Assertions do
  @moduledoc false

  alias Cerberus.Driver
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Phoenix.LiveViewTimeout
  alias Cerberus.Profiling
  alias Cerberus.Session
  alias ExUnit.AssertionError

  @type locator_input :: Locator.t() | keyword() | map()
  @type assert_locator_input :: locator_input() | String.t() | Regex.t()

  defguardp is_locator_input(input)
            when is_list(input) or (is_map(input) and not is_struct(input, Regex))

  defguardp is_assert_locator_input(input)
            when is_binary(input) or is_struct(input, Regex) or is_locator_input(input)

  @spec click(arg, locator_input(), Driver.click_opts()) :: arg when arg: var
  def click(session, locator_input, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_click_locator(locator_input, opts)
    opts = Options.validate_click!(opts)
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :click, fn -> driver.click(session, locator, opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("click", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec fill_in(arg, locator_input(), Driver.fill_in_input_value(), Driver.fill_in_opts()) :: arg when arg: var
  def fill_in(session, locator_input, value, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_fill_in_locator(locator_input, opts)
    opts = Options.validate_fill_in!(opts)
    driver = driver_module_for_session!(session)

    result =
      profile_driver_operation(session, :fill_in, fn -> driver.fill_in(session, locator, to_string(value), opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("fill_in", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec select(arg, locator_input(), Driver.select_opts()) :: arg when arg: var
  def select(session, locator_input, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_select_locator(locator_input, opts)
    opts = Options.validate_select!(opts)
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :select, fn -> driver.select(session, locator, opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("select", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec choose(arg, locator_input(), Driver.choose_opts()) :: arg when arg: var
  def choose(session, locator_input, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_choose_locator(locator_input, opts)
    opts = Options.validate_choose!(opts, "choose/3")
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :choose, fn -> driver.choose(session, locator, opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("choose", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec check(arg, locator_input(), Driver.check_opts()) :: arg when arg: var
  def check(session, locator_input, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_check_locator(locator_input, opts, "check/3")
    opts = Options.validate_check!(opts, "check/3")
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :check, fn -> driver.check(session, locator, opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("check", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec uncheck(arg, locator_input(), Driver.check_opts()) :: arg when arg: var
  def uncheck(session, locator_input, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_check_locator(locator_input, opts, "uncheck/3")
    opts = Options.validate_check!(opts, "uncheck/3")
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :uncheck, fn -> driver.uncheck(session, locator, opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("uncheck", locator_input, opts, reason, observed, failed_session)
    end
  end

  @spec upload(arg, locator_input(), String.t(), Driver.upload_opts()) :: arg when arg: var
  def upload(session, locator_input, path, opts \\ [])

  def upload(session, locator_input, path, opts)
      when is_locator_input(locator_input) and is_binary(path) and is_list(opts) do
    ensure_non_empty_upload_path!(path)
    {locator, opts} = normalize_upload_locator(locator_input, opts)
    opts = Options.validate_upload!(opts)
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :upload, fn -> driver.upload(session, locator, path, opts) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("upload", locator_input, opts, reason, observed, failed_session)
    end
  end

  def upload(_session, locator_input, _path, _opts) when is_locator_input(locator_input) do
    raise ArgumentError, "upload/4 expects a non-empty path string and keyword options"
  end

  @spec submit(arg) :: arg when arg: var
  def submit(session) do
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :submit, fn -> driver.submit_active_form(session, []) end)

    case result do
      {:ok, session, _observed} ->
        session

      {:error, failed_session, observed, reason} ->
        raise AssertionError,
          message: format_error("submit", "active_form", [], reason, observed, failed_session)
    end
  end

  @spec submit(arg, locator_input(), Driver.submit_opts()) :: arg when arg: var
  def submit(session, locator_input, opts \\ []) when is_locator_input(locator_input) and is_list(opts) do
    {locator, opts} = normalize_submit_locator(locator_input, opts)
    opts = Options.validate_submit!(opts)
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, :submit, fn -> driver.submit(session, locator, opts) end)

    case result do
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
    driver_kind = driver_kind(session)

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

  @spec assert_has(arg, assert_locator_input(), Driver.assert_opts()) :: arg when arg: var
  def assert_has(session, locator_input, call_opts \\ [])
      when is_assert_locator_input(locator_input) and is_list(call_opts) do
    call_has_timeout = Keyword.has_key?(call_opts, :timeout)
    {locator, call_opts} = normalize_assert_locator(locator_input, call_opts)
    validated_opts = call_opts |> Options.validate_assert!("assert_has/3") |> prune_nil_match_by_opt()
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

  @spec refute_has(arg, assert_locator_input(), Driver.assert_opts()) :: arg when arg: var
  def refute_has(session, locator_input, call_opts \\ [])
      when is_assert_locator_input(locator_input) and is_list(call_opts) do
    call_has_timeout = Keyword.has_key?(call_opts, :timeout)
    {locator, call_opts} = normalize_assert_locator(locator_input, call_opts)
    validated_opts = call_opts |> Options.validate_assert!("refute_has/3") |> prune_nil_match_by_opt()
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

  @spec run_assertion!(
          Session.t(),
          :assert_has | :refute_has,
          Locator.t(),
          Driver.locator_input(),
          keyword(),
          keyword()
        ) :: Session.t()
  defp run_assertion!(session, op, locator, locator_input, driver_opts, message_opts) do
    driver = driver_module_for_session!(session)
    result = profile_driver_operation(session, op, fn -> apply(driver, op, [session, locator, driver_opts]) end)

    case result do
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

  @spec format_error(
          String.t(),
          locator_input() | :none | String.t(),
          keyword(),
          String.t(),
          Session.observed(),
          Session.t()
        ) :: String.t()
  defp format_error(op, locator, opts, reason, observed, session) do
    transition = observed_transition(observed) || session_transition(session)
    scope = Session.scope(session)
    current_path = session |> Session.current_path() |> Path.normalize()

    base_message = """
    #{op} failed: #{reason}
    locator: #{inspect(locator)}
    opts: #{inspect(opts)}
    current_path: #{inspect(current_path)}
    scope: #{inspect(scope)}
    transition: #{inspect(transition)}
    """

    maybe_append_candidate_values(base_message, reason, observed)
  end

  @spec observed_transition(Session.observed()) :: Session.observed() | nil
  defp observed_transition(observed) when is_map(observed) do
    observed[:transition] || observed["transition"]
  end

  defp observed_transition(_observed), do: nil

  defp maybe_append_candidate_values(message, reason, observed) do
    case candidate_values_for_error(reason, observed) do
      [] ->
        message

      values ->
        {shown, hidden_count} = values |> Enum.uniq() |> split_visible_candidates()

        extra =
          if hidden_count > 0 do
            "\n  ... (#{hidden_count} more)"
          else
            ""
          end

        message <>
          "\npossible candidates:" <>
          Enum.map_join(shown, "", fn value -> "\n  - #{inspect(value)}" end) <> extra
    end
  end

  defp candidate_values_for_error(reason, observed) when is_map(observed) and is_binary(reason) do
    case preferred_candidate_values(observed) do
      [] ->
        fallback_candidate_values(reason, observed)

      values ->
        values
    end
  end

  defp candidate_values_for_error(_reason, _observed), do: []

  defp preferred_candidate_values(observed) when is_map(observed) do
    observed_candidates = map_list_value(observed, :candidate_values)
    result = map_value(observed, :result)

    result_candidates =
      map_list_value(result, :candidate_values) ++
        map_list_value(result, :candidateValues)

    if observed_candidates == [], do: result_candidates, else: observed_candidates
  end

  defp fallback_candidate_values(reason, observed) do
    texts = map_list_value(observed, :texts)
    matched = map_list_value(observed, :matched)

    cond do
      reason == "expected text not found" and texts != [] -> texts
      reason == "unexpected matching text found" and matched != [] -> matched
      String.contains?(reason, "count") and matched != [] -> matched
      true -> []
    end
  end

  defp split_visible_candidates(values) when is_list(values) do
    shown =
      values
      |> Enum.map(&normalize_candidate_value/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.take(8)

    hidden_count = max(length(values) - length(shown), 0)
    {shown, hidden_count}
  end

  defp normalize_candidate_value(value) when is_binary(value) do
    value
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 160)
  end

  defp normalize_candidate_value(value), do: inspect(value)

  defp map_value(map, key) when is_map(map) and is_atom(key) do
    string_key = Atom.to_string(key)

    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, string_key) -> Map.get(map, string_key)
      true -> nil
    end
  end

  defp map_value(_map, _key), do: nil

  defp map_list_value(map, key) do
    case map_value(map, key) do
      list when is_list(list) ->
        list
        |> Enum.map(&normalize_candidate_value/1)
        |> Enum.reject(&(&1 == ""))

      _ ->
        []
    end
  end

  defp resolve_assert_timeout(_session, true, validated_timeout), do: validated_timeout
  defp resolve_assert_timeout(%LiveSession{assert_timeout_ms: timeout}, false, _validated_timeout), do: timeout

  defp resolve_assert_timeout(%BrowserSession{assert_timeout_ms: timeout}, false, _validated_timeout), do: timeout

  defp resolve_assert_timeout(_session, false, _validated_timeout), do: 0

  defp profile_driver_operation(session, op, fun) when is_atom(op) and is_function(fun, 0) do
    Profiling.measure({:driver_operation, driver_kind(session), op}, fun)
  end

  defp session_transition(%{last_result: %{transition: transition}}), do: transition
  defp session_transition(_session), do: nil

  defp driver_kind(%StaticSession{}), do: :static
  defp driver_kind(%LiveSession{}), do: :live
  defp driver_kind(%BrowserSession{}), do: :browser

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
    {locator, opts}
  end

  defp normalize_fill_in_locator(locator_input, opts) do
    normalize_form_action_locator(locator_input, opts)
  end

  defp normalize_upload_locator(locator_input, opts) do
    normalize_form_action_locator(locator_input, opts)
  end

  defp normalize_check_locator(locator_input, opts, _op_name) do
    normalize_form_action_locator(locator_input, opts)
  end

  defp normalize_select_locator(locator_input, opts) do
    normalize_form_action_locator(locator_input, opts)
  end

  defp normalize_choose_locator(locator_input, opts) do
    normalize_check_locator(locator_input, opts, "choose/3")
  end

  defp normalize_form_action_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)
    opts = merge_locator_selector_opts(locator, opts)
    {locator, opts}
  end

  defp normalize_assert_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)
    normalize_assert_locator_kind(locator, opts)
  end

  defp normalize_assert_locator_kind(%Locator{} = locator, opts) do
    if locator_assertion_requires_locator_engine?(locator) do
      {locator, opts}
    else
      normalize_assert_locator_simple_kind(locator, opts)
    end
  end

  defp normalize_submit_locator(locator_input, opts) do
    locator = Locator.normalize(locator_input)
    opts = merge_locator_selector_opts(locator, opts)
    {locator, opts}
  end

  defp normalize_assert_locator_simple_kind(%Locator{kind: :text} = locator, opts), do: {locator, opts}

  defp normalize_assert_locator_simple_kind(%Locator{kind: :role, value: value} = locator, opts) do
    role_match_by = Locator.resolved_kind(locator)
    normalized_locator_opts = locator.opts |> Keyword.delete(:role) |> put_match_by(role_match_by)
    {%{locator | kind: :text, value: value, opts: normalized_locator_opts}, opts}
  end

  defp normalize_assert_locator_simple_kind(%Locator{kind: kind, value: value} = locator, opts)
       when kind in [:label, :link, :button, :placeholder, :title, :alt, :aria_label] do
    {%{locator | kind: :text, value: value, opts: put_match_by(locator.opts, kind)}, opts}
  end

  defp normalize_assert_locator_simple_kind(%Locator{kind: :testid, value: value} = locator, opts) do
    normalized_opts = locator.opts |> put_match_by(:testid) |> ensure_exact_opt(true)
    {%{locator | kind: :text, value: value, opts: normalized_opts}, opts}
  end

  defp locator_assertion_requires_locator_engine?(%Locator{kind: kind}) when kind in [:and, :or, :not, :css], do: true

  defp locator_assertion_requires_locator_engine?(%Locator{opts: locator_opts}) do
    Keyword.has_key?(locator_opts, :selector) or
      Keyword.has_key?(locator_opts, :has) or
      Keyword.has_key?(locator_opts, :has_not) or
      Keyword.has_key?(locator_opts, :from)
  end

  defp merge_locator_selector_opts(%Locator{opts: locator_opts}, opts) when is_list(locator_opts) do
    selector_opt = Keyword.take(locator_opts, [:selector])
    Keyword.merge(selector_opt, opts)
  end

  defp prune_nil_match_by_opt(opts) do
    if Keyword.get(opts, :match_by) == nil do
      Keyword.delete(opts, :match_by)
    else
      opts
    end
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
