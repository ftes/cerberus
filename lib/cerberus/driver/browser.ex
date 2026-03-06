defmodule Cerberus.Driver.Browser do
  @moduledoc false

  @behaviour Cerberus.Driver

  alias Cerberus.Browser.Native, as: BrowserNative
  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Config
  alias Cerberus.Driver.Browser.Evaluate
  alias Cerberus.Driver.Browser.Expressions
  alias Cerberus.Driver.Browser.Extensions
  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Driver.LocatorOps
  alias Cerberus.Html
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Profiling
  alias Cerberus.Query
  alias Cerberus.Session
  alias Cerberus.Session.Config, as: SessionConfig
  alias Cerberus.Session.LastResult
  alias Cerberus.UploadFile
  alias ExUnit.AssertionError

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @transient_eval_retry_interval_ms 25
  @value_assertion_poll_interval_ms 50
  @transient_eval_retry_min_budget_ms 3_000
  @transient_ready_retry_min_budget_ms 3_000
  @transient_navigation_eval_markers [
    "JSWindowActorChild cannot send",
    "argument is not a global object",
    "Inspected target navigated or closed",
    "Cannot find context with specified id",
    "execution contexts cleared",
    "DiscardedBrowsingContextError",
    "no such frame",
    "navigation canceled by concurrent navigation"
  ]
  @user_context_supervisor Cerberus.Driver.Browser.UserContextSupervisor
  @empty_browser_context_defaults %{viewport: nil, user_agent: nil, init_scripts: [], popup_mode: :allow}
  @action_failure_reason_messages %{
    "submit_target_failed" => "no submit button matched locator",
    "field_fill_failed" => "no form field matched locator",
    "field_not_select" => "matched field is not a select element",
    "field_not_radio" => "matched field is not a radio input",
    "field_not_checkbox" => "matched field is not a checkbox",
    "target_detached" => "matched target is no longer attached",
    "target_not_visible" => "matched element is not visible",
    "data_method_target_missing" => "data-method element must define `data-to` or `href`",
    "option_not_found" => "browser select failed: option_not_found",
    "option_disabled" => "browser select failed: option_disabled",
    "select_not_multiple" => "browser select failed: select_not_multiple",
    "upload_failed" => "browser upload failed: upload_failed"
  }

  @type viewport :: %{width: pos_integer(), height: pos_integer()}
  @type browser_context_defaults :: %{
          viewport: viewport() | nil,
          user_agent: String.t() | nil,
          init_scripts: [String.t()],
          popup_mode: :allow | :same_tab
        }

  @type t :: %__MODULE__{
          user_context_pid: pid(),
          tab_id: String.t(),
          browser_name: :chrome | :firefox,
          bidi_opts: keyword(),
          endpoint: module() | nil,
          base_url: String.t(),
          assert_timeout_ms: non_neg_integer(),
          ready_timeout_ms: pos_integer(),
          ready_quiet_ms: pos_integer(),
          browser_context_defaults: browser_context_defaults(),
          active_form_selector: String.t() | nil,
          scope: Session.scope_value(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct user_context_pid: nil,
            tab_id: nil,
            browser_name: :chrome,
            bidi_opts: [],
            endpoint: nil,
            base_url: nil,
            assert_timeout_ms: 0,
            ready_timeout_ms: @default_ready_timeout_ms,
            ready_quiet_ms: @default_ready_quiet_ms,
            browser_context_defaults: @empty_browser_context_defaults,
            active_form_selector: nil,
            scope: nil,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    owner = self()
    context_defaults = browser_context_defaults(opts)
    browser_name = Runtime.browser_name(opts)
    session_bidi_opts = session_bidi_opts(opts, browser_name)
    ensure_popup_mode_supported!(browser_name, context_defaults.popup_mode)

    start_opts =
      opts
      |> Keyword.put(:owner, owner)
      |> Keyword.put(:browser_name, browser_name)
      |> Keyword.put(:browser_context_defaults, context_defaults)

    {user_context_pid, base_url} =
      case start_user_context(start_opts) do
        {:ok, user_context_pid} ->
          {user_context_pid, UserContextProcess.base_url(user_context_pid)}

        {:error, reason} ->
          raise ArgumentError, "failed to initialize browser driver: #{inspect(reason)}"
      end

    tab_id =
      case UserContextProcess.active_tab(user_context_pid) do
        value when is_binary(value) -> value
        _ -> raise ArgumentError, "failed to initialize browser driver: missing active tab"
      end

    %__MODULE__{
      user_context_pid: user_context_pid,
      tab_id: tab_id,
      browser_name: browser_name,
      bidi_opts: session_bidi_opts,
      endpoint: Keyword.get(opts, :endpoint) || Application.get_env(:cerberus, :endpoint),
      base_url: base_url,
      assert_timeout_ms:
        SessionConfig.assert_timeout_from_opts!(opts, SessionConfig.live_browser_assert_timeout_default_ms()),
      ready_timeout_ms: ready_timeout_ms(opts),
      ready_quiet_ms: ready_quiet_ms(opts),
      browser_context_defaults: context_defaults
    }
  end

  @impl true
  @spec open_tab(t()) :: t()
  def open_tab(%__MODULE__{} = session) do
    case UserContextProcess.open_tab(session.user_context_pid) do
      {:ok, tab_id} ->
        %{
          session
          | tab_id: tab_id,
            active_form_selector: nil,
            scope: nil,
            current_path: nil
        }

      {:error, reason, details} ->
        raise ArgumentError, "failed to open browser tab: #{reason} (#{inspect(details)})"
    end
  end

  @impl true
  @spec switch_tab(t(), Session.t()) :: t()
  def switch_tab(%__MODULE__{} = session, %__MODULE__{} = target_session) do
    if session.user_context_pid != target_session.user_context_pid do
      raise ArgumentError,
            "cannot switch tab across different browser users; start a new browser session for user isolation"
    end

    case UserContextProcess.switch_tab(session.user_context_pid, target_session.tab_id) do
      :ok ->
        target_session

      {:error, reason, details} ->
        raise ArgumentError, "failed to switch browser tab: #{reason} (#{inspect(details)})"
    end
  end

  def switch_tab(%__MODULE__{}, _target_session) do
    raise ArgumentError, "cannot switch browser tab to a non-browser session"
  end

  @impl true
  @spec close_tab(t()) :: t()
  def close_tab(%__MODULE__{} = session) do
    case UserContextProcess.close_tab(session.user_context_pid, session.tab_id) do
      :ok ->
        next_tab_id = UserContextProcess.active_tab(session.user_context_pid)

        if is_binary(next_tab_id) do
          %{
            session
            | tab_id: next_tab_id,
              active_form_selector: nil,
              scope: nil,
              current_path: nil
          }
        else
          raise ArgumentError, "failed to close browser tab: no active tab selected"
        end

      {:error, reason, details} ->
        raise ArgumentError, "failed to close browser tab: #{reason} (#{inspect(details)})"
    end
  end

  @impl true
  def open_browser(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
    {state, html, url} = html_snapshot!(session)
    endpoint = Application.get_env(:cerberus, :endpoint)
    path = OpenBrowser.write_snapshot!(html, snapshot_base_url(state.base_url, url), endpoint)
    _ = open_fun.(path)
    session
  end

  @impl true
  def render_html(%__MODULE__{} = session, callback) when is_function(callback, 1) do
    {_state, html, _url} = html_snapshot!(session)
    _ = callback.(LazyHTML.from_document(html))
    session
  end

  @impl true
  def unwrap(%__MODULE__{} = session, fun) when is_function(fun, 1) do
    _ =
      fun.(%BrowserNative{
        user_context_pid: session.user_context_pid,
        tab_id: session.tab_id
      })

    session
  end

  @spec screenshot(t(), Options.screenshot_opts()) :: t()
  def screenshot(%__MODULE__{} = session, opts \\ []) when is_list(opts) do
    state = state!(session)
    path = screenshot_path(opts)
    full_page = screenshot_full_page(opts)

    case capture_screenshot(state.tab_id, full_page, bidi_opts(state)) do
      {:ok, %{"data" => data}} when is_binary(data) ->
        write_screenshot!(path, data)
        session

      {:ok, payload} ->
        raise ArgumentError, "failed to capture browser screenshot: unexpected payload #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "failed to capture browser screenshot: #{reason} (#{inspect(details)})"
    end
  end

  @doc false
  @spec refresh_path(t()) :: t()
  def refresh_path(%__MODULE__{} = session) do
    state = state!(session)

    case eval_json_transient_read(state, Expressions.current_path()) do
      {:ok, %{"path" => path}} when is_binary(path) ->
        %{session | current_path: path}

      _ ->
        session
    end
  end

  @doc false
  @spec resolve_within_scope(t(), Locator.t(), Session.scope_value()) ::
          {:ok, Session.scope_value()} | {:error, String.t()}
  def resolve_within_scope(%__MODULE__{} = session, %Locator{} = locator, scope \\ nil) do
    state = state!(session)

    with {:ok, snapshot} <- eval_json_transient_read(state, Expressions.within_scope_snapshot(scope)),
         :ok <- validate_within_scope_snapshot(snapshot),
         html when is_binary(html) <- Map.get(snapshot, "html"),
         {:ok, target} <- Html.find_scope_target(html, locator, Map.get(snapshot, "scopeSelector")),
         {:ok, resolved_scope} <- build_within_scope_from_target(state, scope, snapshot, target) do
      {:ok, resolved_scope}
    else
      {:error, reason, _details} ->
        {:error, "failed to inspect browser scope for within/3: #{reason}"}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      _other ->
        {:error, "failed to inspect browser scope for within/3"}
    end
  end

  @impl true
  def within(%__MODULE__{} = session, %Locator{} = locator, callback) when is_function(callback, 1) do
    previous_scope = Session.scope(session)

    resolved_scope =
      case resolve_within_scope(session, locator, previous_scope) do
        {:ok, scope} ->
          scope

        {:error, reason} ->
          raise AssertionError, message: "within/3 failed: #{reason}"
      end

    scoped_session = Session.with_scope(session, resolved_scope)
    callback_result = callback.(scoped_session)

    restore_scope!(callback_result, previous_scope)
  end

  @doc false
  @spec assert_path(t(), String.t() | Regex.t(), Options.path_opts()) ::
          {:ok, t(), map()} | {:error, t(), map(), String.t()}
  @impl true
  def assert_path(%__MODULE__{} = session, expected, opts) when is_binary(expected) or is_struct(expected, Regex) do
    run_path_assertion(session, expected, opts, :assert_path)
  end

  @doc false
  @spec refute_path(t(), String.t() | Regex.t(), Options.path_opts()) ::
          {:ok, t(), map()} | {:error, t(), map(), String.t()}
  @impl true
  def refute_path(%__MODULE__{} = session, expected, opts) when is_binary(expected) or is_struct(expected, Regex) do
    run_path_assertion(session, expected, opts, :refute_path)
  end

  @impl true
  def default_assert_timeout_ms(%__MODULE__{} = session), do: session.assert_timeout_ms

  @impl true
  def run_path_assertion(%__MODULE__{} = session, expected, opts, timeout, op) when op in [:assert_path, :refute_path] do
    driver_opts = Keyword.put(opts, :timeout, timeout)

    case apply(__MODULE__, op, [session, expected, driver_opts]) do
      {:ok, updated_session, _observed} ->
        updated_session

      {:error, _failed_session, observed, _reason} ->
        raise AssertionError,
          message: Cerberus.Path.format_assertion_error(Atom.to_string(op), observed)
    end
  end

  @doc false
  @spec wait_for_assertion_signal(t(), non_neg_integer()) :: t()
  def wait_for_assertion_signal(%__MODULE__{} = session, timeout_ms) when is_integer(timeout_ms) and timeout_ms >= 0 do
    state = state!(session)

    if timeout_ms > 0 do
      quiet_ms = max(min(session.ready_quiet_ms, timeout_ms), 1)

      _ =
        Profiling.measure({:browser_wait, :await_ready, :assertion_signal}, fn ->
          UserContextProcess.await_ready(
            state.user_context_pid,
            [timeout_ms: timeout_ms, quiet_ms: quiet_ms],
            state.tab_id
          )
        end)
    end

    refresh_path(session)
  end

  @impl true
  def visit(%__MODULE__{} = session, path, _opts) do
    state = state!(session)
    url = to_absolute_url(state.base_url, path)

    case navigate_browser(state, url) do
      {:ok, _} ->
        {ready_state, readiness} = await_ready_after_visit!(state)
        snapshot_after_visit!(session, ready_state, readiness)

      {:error, reason, details} ->
        handle_visit_navigation_error!(session, state, reason, details)
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.click(locator, opts)
    do_resolved_click(session, state, expected, match_opts)
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{} = locator, value, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    do_resolved_fill_in(session, state, expected, value, match_opts)
  end

  @impl true
  def select(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    option = Keyword.fetch!(opts, :option)
    do_resolved_select(session, state, expected, option, match_opts)
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    do_resolved_choose(session, state, expected, match_opts)
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    do_resolved_toggle_checkbox(session, state, expected, match_opts, true, :check)
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    do_resolved_toggle_checkbox(session, state, expected, match_opts, false, :uncheck)
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{} = locator, path, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    do_resolved_upload(session, state, expected, path, match_opts)
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.submit(locator, opts)
    do_resolved_submit(session, state, expected, match_opts)
  end

  @impl true
  def submit_active_form(%__MODULE__{} = session, _opts) do
    state = state!(session)

    case state.active_form_selector do
      selector when is_binary(selector) and selector != "" ->
        case do_resolved_submit(session, state, "", match_by: :button, scope_selector: selector) do
          {:error, failed_session, observed, "no submit button matched locator"} ->
            {:error, failed_session, observed, "submit/1 could not find a submit button in the active form"}

          other ->
            other
        end

      _ ->
        observed = %{action: :submit, path: state.current_path}

        {:error, session, observed,
         "submit/1 requires an active form; call fill_in/select/choose/check/uncheck/upload first"}
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    match_opts = locator_match_opts(locator, Keyword.delete(opts, :timeout))
    visible = assertion_visibility(opts, locator)
    assertion_runner = if(locator_assertion_requires_locator_engine?(locator), do: :locator, else: :text)

    case run_assertion_by_mode(assertion_runner, state, locator, expected, visible, match_opts, timeout_ms, :assert) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :assert_has, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    match_opts = locator_match_opts(locator, Keyword.delete(opts, :timeout))
    visible = assertion_visibility(opts, locator)

    case run_assertion_by_mode(:locator, state, locator, nil, visible, match_opts, timeout_ms, :assert) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :assert_has, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    match_opts = locator_match_opts(locator, Keyword.delete(opts, :timeout))
    visible = assertion_visibility(opts, locator)
    assertion_runner = if(locator_assertion_requires_locator_engine?(locator), do: :locator, else: :text)

    case run_assertion_by_mode(assertion_runner, state, locator, expected, visible, match_opts, timeout_ms, :refute) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :refute_has, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    match_opts = locator_match_opts(locator, Keyword.delete(opts, :timeout))
    visible = assertion_visibility(opts, locator)

    case run_assertion_by_mode(:locator, state, locator, nil, visible, match_opts, timeout_ms, :refute) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :refute_has, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def assert_value(%__MODULE__{} = session, %Locator{} = locator, expected, opts)
      when (is_binary(expected) or is_struct(expected, Regex)) and is_list(opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    {field_expected, match_opts} = LocatorOps.form(locator, Keyword.delete(opts, :timeout))

    case run_value_assertion_by_mode(state, field_expected, match_opts, expected, timeout_ms, :assert) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :assert_value, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def refute_value(%__MODULE__{} = session, %Locator{} = locator, expected, opts)
      when (is_binary(expected) or is_struct(expected, Regex)) and is_list(opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    {field_expected, match_opts} = LocatorOps.form(locator, Keyword.delete(opts, :timeout))

    case run_value_assertion_by_mode(state, field_expected, match_opts, expected, timeout_ms, :refute) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :refute_value, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def assert_download(%__MODULE__{} = session, filename, opts) when is_binary(filename) and is_list(opts) do
    Extensions.assert_download(session, filename, opts)
  end

  defp do_resolved_click(session, state, expected, opts) do
    kind = Keyword.get(opts, :kind, :any)

    case perform_action(session, state, :click, expected, opts) do
      {:ok, %{"target" => target} = result} when is_map(target) ->
        click_target_result(session, state, target, result, opts)

      {:ok, result} ->
        target = Map.get(result, "target")
        observed = %{action: :click, path: state.current_path, target: target}
        {:error, session, observed, no_clickable_error(kind)}

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  end

  defp do_resolved_submit(session, state, expected, opts) do
    case perform_action(session, state, :submit, expected, opts) do
      {:ok, %{"target" => %{"kind" => "button"} = button} = result} ->
        submit_result(session, state, button, result, opts)

      {:ok, result} ->
        target = Map.get(result, "target")
        observed = %{action: :submit, path: state.current_path, target: target}
        {:error, session, observed, "no submit button matched locator"}

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  end

  defp do_resolved_fill_in(session, state, expected, value, opts) do
    case perform_action(session, state, :fill_in, expected, opts, %{value: to_string(value)}) do
      {:ok, %{"target" => field} = result} when is_map(field) ->
        fill_in_result(session, state, field, value, result)

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  end

  defp do_resolved_select(session, state, expected, option, opts) do
    exact_option = Keyword.get(opts, :exact_option, true)
    option_values = option |> List.wrap() |> Enum.map(&to_string/1)
    option_list_input = is_list(option)

    case perform_action(
           session,
           state,
           :select,
           expected,
           opts,
           %{option: option_values, exactOption: exact_option, optionListInput: option_list_input}
         ) do
      {:ok, %{"target" => field} = result} when is_map(field) ->
        select_result(session, state, field, option, result)

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  end

  defp do_resolved_choose(session, state, expected, opts) do
    case perform_action(session, state, :choose, expected, opts) do
      {:ok, %{"target" => field} = result} when is_map(field) ->
        choose_result(session, state, field, result)

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  end

  defp do_resolved_toggle_checkbox(session, state, expected, opts, checked?, op) do
    case perform_action(session, state, op, expected, opts) do
      {:ok, %{"target" => field} = result} when is_map(field) ->
        checkbox_result(session, state, field, checked?, op, result)

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  end

  defp do_resolved_upload(session, state, expected, path, opts) do
    file = UploadFile.read!(path)

    payload = %{
      file: %{
        fileName: file.file_name,
        mimeType: file.mime_type,
        lastModified: file.last_modified_unix_ms,
        contentBase64: Base.encode64(file.content)
      }
    }

    case perform_action(session, state, :upload, expected, opts, payload) do
      {:ok, %{"target" => field} = result} when is_map(field) ->
        upload_result(session, state, field, file.file_name, result)

      {:error, _failed_session, _observed, _reason} = error ->
        error
    end
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{action: :upload, path: state.current_path, file_path: path}
      {:error, session, observed, Exception.message(error)}
  end

  defp perform_action(session, state, op, expected, opts, extra_payload \\ %{})
       when is_list(opts) and is_map(extra_payload) do
    timeout_ms = action_timeout_ms(opts, state.ready_timeout_ms)
    payload = build_action_payload(state, op, expected, opts, timeout_ms, extra_payload)

    case eval_json(state, Expressions.action_perform(payload), command_timeout_ms(timeout_ms)) do
      {:ok, result} ->
        action_perform_result(session, state, op, opts, result)

      {:error, reason, details} ->
        observed = %{action: op, path: state.current_path, details: details}
        {:error, session, observed, "#{inspect_failure_prefix(op)}: #{reason}"}
    end
  end

  defp action_perform_result(_session, _state, _op, _opts, %{"ok" => true} = result) do
    {:ok, result}
  end

  defp action_perform_result(session, state, op, opts, %{"ok" => false} = result) do
    reason = action_failure_reason(op, opts, result, "failed to perform browser action")

    observed = %{
      action: op,
      path: Map.get(result, "path", state.current_path),
      match_count: Map.get(result, "matchCount"),
      candidate_count: Map.get(result, "candidateCount"),
      candidate_values: Map.get(result, "candidateValues", []),
      reason: Map.get(result, "reason"),
      result: result
    }

    {:error, session, observed, reason}
  end

  defp action_perform_result(session, state, op, _opts, result) do
    observed = %{action: op, path: state.current_path, result: result}
    {:error, session, observed, "unexpected action execution payload"}
  end

  defp action_failure_reason(op, opts, result, fallback) do
    reason = Map.get(result, "reason")

    cond do
      reason == "no elements matched locator" ->
        no_action_target_error(op, opts)

      reason == "matched element count did not satisfy count constraints" ->
        count_constraint_reason(result, opts)

      reason == "click_target_failed" ->
        no_clickable_error(Keyword.get(opts, :kind, :any))

      reason == "field_disabled" ->
        action_disabled_reason(op)

      is_binary(reason) ->
        Map.get(@action_failure_reason_messages, reason, reason)

      true ->
        fallback
    end
  end

  defp count_constraint_reason(result, opts) do
    match_count = Map.get(result, "matchCount", 0)

    case Query.apply_count_constraints(match_count, opts) do
      :ok -> "matched element count did not satisfy count constraints"
      {:error, reason} -> reason
    end
  end

  defp action_disabled_reason(:select), do: "matched select field is disabled"
  defp action_disabled_reason(_op), do: "matched field is disabled"

  defp build_action_payload(state, op, expected, opts, timeout_ms, extra_payload)
       when is_list(opts) and is_integer(timeout_ms) and timeout_ms >= 0 and is_map(extra_payload) do
    {between_min, between_max} = between_bounds(opts)

    Map.merge(
      %{
        op: Atom.to_string(op),
        scopeSelector: action_scope_selector(state, opts),
        locator: action_locator_payload(opts),
        expected: text_expectation_payload(expected),
        exact: Keyword.get(opts, :exact, false),
        normalizeWs: Keyword.get(opts, :normalize_ws, true),
        force: Keyword.get(opts, :force, false),
        matchBy: action_match_by(opts, op),
        kind: action_kind(opts, op),
        count: Keyword.get(opts, :count),
        min: Keyword.get(opts, :min),
        max: Keyword.get(opts, :max),
        betweenMin: between_min,
        betweenMax: between_max,
        first: Keyword.get(opts, :first, false),
        last: Keyword.get(opts, :last, false),
        nth: Keyword.get(opts, :nth),
        index: Keyword.get(opts, :index),
        checked: Keyword.get(opts, :checked),
        disabled: Keyword.get(opts, :disabled),
        selected: Keyword.get(opts, :selected),
        readonly: Keyword.get(opts, :readonly),
        visible: Keyword.get(opts, :visible),
        readyTimeoutMs: timeout_ms,
        timeoutMs: timeout_ms,
        pollMs: 100
      },
      extra_payload
    )
  end

  defp action_scope_selector(state, opts) do
    scope = Session.scope(state)

    case Keyword.get(opts, :scope_selector) do
      selector when is_binary(selector) and selector != "" ->
        case scope do
          %{} = scope_map -> Map.put(scope_map, :selector, selector)
          _ -> selector
        end

      _ ->
        scope
    end
  end

  defp no_action_target_error(:click, opts), do: no_clickable_error(Keyword.get(opts, :kind, :any))
  defp no_action_target_error(:submit, _opts), do: "no submit button matched locator"
  defp no_action_target_error(:upload, _opts), do: "no file input matched locator"
  defp no_action_target_error(_op, _opts), do: "no form field matched locator"

  defp action_match_by(opts, op) do
    default =
      if op in [:click, :submit] do
        :text
      else
        :label
      end

    opts
    |> Keyword.get(:match_by, default)
    |> Atom.to_string()
  end

  defp action_kind(opts, :click), do: opts |> Keyword.get(:kind, :any) |> Atom.to_string()
  defp action_kind(_opts, _op), do: nil

  defp action_locator_payload(opts) do
    case Keyword.get(opts, :locator) do
      %Locator{} = locator -> locator_payload(locator)
      _ -> nil
    end
  end

  defp locator_payload(%Locator{kind: kind, value: members, opts: opts}) when kind in [:scope, :and, :or, :not] do
    %{
      kind: Atom.to_string(kind),
      members: Enum.map(members, &locator_payload/1),
      opts: locator_opts_payload(opts)
    }
  end

  defp locator_payload(%Locator{kind: :css, value: selector, opts: opts}) do
    %{
      kind: "css",
      value: selector,
      opts: locator_opts_payload(opts)
    }
  end

  defp locator_payload(%Locator{kind: kind, value: expected, opts: opts}) do
    %{
      kind: Atom.to_string(kind),
      expected: text_expectation_payload(expected),
      opts: locator_opts_payload(opts)
    }
  end

  defp locator_opts_payload(opts) when is_list(opts) do
    %{
      role: Keyword.get(opts, :role),
      exact: Keyword.get(opts, :exact),
      normalizeWs: Keyword.get(opts, :normalize_ws),
      has: nested_locator_payload(Keyword.get(opts, :has)),
      has_not: nested_locator_payload(Keyword.get(opts, :has_not)),
      from: nested_locator_payload(Keyword.get(opts, :from)),
      checked: Keyword.get(opts, :checked),
      disabled: Keyword.get(opts, :disabled),
      selected: Keyword.get(opts, :selected),
      readonly: Keyword.get(opts, :readonly),
      visible: Keyword.get(opts, :visible)
    }
  end

  defp nested_locator_payload(%Locator{} = locator), do: locator_payload(locator)
  defp nested_locator_payload(_other), do: nil

  defp inspect_failure_prefix(op) when op in [:click], do: "failed to inspect clickable elements"
  defp inspect_failure_prefix(op) when op in [:submit], do: "failed to inspect submit controls"
  defp inspect_failure_prefix(op) when op in [:upload], do: "failed to inspect upload fields"
  defp inspect_failure_prefix(_op), do: "failed to inspect form fields"

  defp click_target_result(session, state, target, result, opts) when is_map(target) and is_map(result) do
    await_failure_observed = %{
      action: :click,
      clicked: target["text"],
      path: state.current_path,
      target: target
    }

    maybe_await_ready_result(session, state, result, opts, await_failure_observed, fn {ready_state, readiness} ->
      path =
        result
        |> action_result_path(ready_state.current_path)
        |> ready_path(readiness)

      next_state = %{ready_state | current_path: path, active_form_selector: nil}

      observed = %{
        action: :click,
        clicked: target["text"],
        path: path,
        target: target,
        readiness: readiness
      }

      {:ok, update_session(session, next_state, :click, observed), observed}
    end)
  end

  defp submit_result(session, state, button, result, opts) when is_map(result) do
    await_failure_observed = %{
      action: :submit,
      clicked: button["text"],
      path: state.current_path,
      target: button
    }

    maybe_await_ready_result(session, state, result, opts, await_failure_observed, fn {ready_state, readiness} ->
      path =
        result
        |> action_result_path(ready_state.current_path)
        |> ready_path(readiness)

      next_state = %{ready_state | current_path: path}

      observed = %{
        action: :submit,
        clicked: button["text"],
        path: path,
        target: button,
        readiness: readiness
      }

      {:ok, update_session(session, next_state, :submit, observed), observed}
    end)
  end

  defp fill_in_result(session, state, field, value, result) when is_map(result) do
    path = action_result_path(result, state.current_path)
    next_state = %{state | current_path: path, active_form_selector: target_form_selector(field, state)}

    observed = %{
      action: :fill_in,
      path: path,
      field: field,
      value: value
    }

    {:ok, update_session(session, next_state, :fill_in, observed), observed}
  end

  defp select_result(session, state, field, option, result) when is_map(result) do
    path = action_result_path(result, state.current_path)
    next_state = %{state | current_path: path, active_form_selector: target_form_selector(field, state)}

    observed = %{
      action: :select,
      path: path,
      field: field,
      option: option,
      value: Map.get(result, "value")
    }

    {:ok, update_session(session, next_state, :select, observed), observed}
  end

  defp choose_result(session, state, field, result) when is_map(result) do
    path = action_result_path(result, state.current_path)
    next_state = %{state | current_path: path, active_form_selector: target_form_selector(field, state)}

    observed = %{
      action: :choose,
      path: path,
      field: field,
      value: Map.get(result, "value")
    }

    {:ok, update_session(session, next_state, :choose, observed), observed}
  end

  defp checkbox_result(session, state, field, checked?, op, result) when is_map(result) do
    path = action_result_path(result, state.current_path)
    next_state = %{state | current_path: path, active_form_selector: target_form_selector(field, state)}

    observed = %{
      action: op,
      path: path,
      field: field,
      checked: checked?
    }

    {:ok, update_session(session, next_state, op, observed), observed}
  end

  defp upload_result(session, state, field, file_name, result) when is_map(result) do
    path = action_result_path(result, state.current_path)
    next_state = %{state | current_path: path, active_form_selector: target_form_selector(field, state)}

    observed = %{
      action: :upload,
      path: path,
      field: field,
      file_name: file_name
    }

    {:ok, update_session(session, next_state, :upload, observed), observed}
  end

  defp target_form_selector(target, state) when is_map(target) do
    case Map.get(target, "formSelector") do
      selector when is_binary(selector) and selector != "" -> selector
      _ -> state.active_form_selector
    end
  end

  defp maybe_await_ready_result(session, state, result, opts, fallback_observed, on_success)
       when is_map(result) and is_list(opts) and is_map(fallback_observed) and is_function(on_success, 1) do
    if await_ready_required?(result) do
      maybe_await_ready(session, state, result, opts, fallback_observed, on_success)
    else
      readiness = inline_settle_readiness(result)
      on_success.({state, readiness})
    end
  end

  defp maybe_await_ready(session, state, result, opts, fallback_observed, on_success) do
    case await_driver_ready(state, action_timeout_ms(opts, state.ready_timeout_ms)) do
      {:ok, ready_state, readiness} ->
        on_success.({ready_state, readiness})

      {:error, reason, readiness} ->
        maybe_recover_action_readiness_error(
          session,
          state,
          result,
          fallback_observed,
          on_success,
          reason,
          readiness
        )
    end
  end

  defp maybe_recover_action_readiness_error(session, state, result, fallback_observed, on_success, reason, readiness) do
    action = Map.get(fallback_observed, :action)

    if recoverable_action_readiness_error?(action, reason, readiness) do
      recovered_readiness =
        readiness
        |> Map.put_new("recoveredFrom", reason)
        |> Map.put_new("reason", "recoverable_action_readiness_error")

      on_success.({state, recovered_readiness})
    else
      observed = Map.merge(fallback_observed, %{readiness: readiness, result: result})
      {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp await_ready_required?(%{"needsAwaitReady" => value}) when is_boolean(value), do: value
  defp await_ready_required?(_result), do: true

  defp inline_settle_readiness(result) when is_map(result) do
    %{
      "ok" => true,
      "reason" => "in-action-settle",
      "skippedAwaitReady" => true,
      "settle" => Map.get(result, "settle")
    }
  end

  defp action_result_path(%{"path" => path}, _fallback_path) when is_binary(path), do: path
  defp action_result_path(_result, fallback_path), do: fallback_path

  defp ready_path(path, %{"path" => ready_path}) when is_binary(path) and is_binary(ready_path) and ready_path != "" do
    ready_path
  end

  defp ready_path(path, _readiness) when is_binary(path), do: path

  defp with_snapshot(state) do
    case eval_json_transient_read(state, Expressions.snapshot(Session.scope(state))) do
      {:ok, snapshot} ->
        snapshot = %{
          path: snapshot["path"],
          title: snapshot["title"] || "",
          visible: snapshot["visible"] || [],
          hidden: snapshot["hidden"] || []
        }

        {%{state | current_path: snapshot.path}, snapshot}

      {:error, reason, details} ->
        {:error, reason, details}
    end
  end

  defp navigate_browser(state, url) do
    Profiling.measure({:browser_wait, :navigate}, fn ->
      UserContextProcess.navigate(state.user_context_pid, url, state.tab_id)
    end)
  end

  defp snapshot_after_visit!(session, state, readiness) do
    case with_snapshot(state) do
      {state, snapshot} ->
        update_session(session, state, :visit, %{path: snapshot.path, title: snapshot.title, readiness: readiness})

      {:error, reason, details} ->
        raise ArgumentError,
              "failed to collect browser snapshot after visit: #{reason} (#{inspect(details)})"
    end
  end

  defp handle_visit_navigation_error!(session, state, reason, details) do
    if navigate_interrupted_by_followup?(reason, details) do
      {ready_state, readiness} = await_ready_after_navigation_interrupt!(state)
      snapshot_after_visit!(session, ready_state, readiness)
    else
      raise ArgumentError, "browser navigate failed: #{reason} (#{inspect(details)})"
    end
  end

  defp await_ready_after_visit!(state) do
    case await_driver_ready(state) do
      {:ok, ready_state, readiness} ->
        {ready_state, readiness}

      {:error, ready_reason, ready_details} ->
        if recoverable_visit_readiness_error?(ready_reason, ready_details) do
          recovered_readiness =
            ready_details
            |> Map.put_new("recoveredFrom", ready_reason)
            |> Map.put("reason", "visit_snapshot_recovery")

          {state, recovered_readiness}
        else
          raise ArgumentError,
                "browser visit readiness failed: #{ready_reason} (#{inspect(ready_details)})"
        end
    end
  end

  defp await_ready_after_navigation_interrupt!(state) do
    case await_driver_ready(state) do
      {:ok, ready_state, readiness} ->
        {ready_state, readiness}

      {:error, ready_reason, ready_details} ->
        raise ArgumentError,
              "browser navigate interrupted and readiness wait failed: #{ready_reason} (#{inspect(ready_details)})"
    end
  end

  defp navigate_interrupted_by_followup?(reason, details)
       when reason in ["unknown error", "navigation canceled by concurrent navigation"] and is_map(details) do
    message = details["message"] || details[:message] || ""
    is_binary(message) and String.contains?(message, "navigation canceled by concurrent navigation")
  end

  defp navigate_interrupted_by_followup?(_reason, _details), do: false

  defp eval_json(state, expression, timeout_ms)

  defp eval_json(state, expression, timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    evaluate_result =
      Profiling.measure({:browser_wait, :evaluate_with_timeout}, fn ->
        Evaluate.with_dialog_unblock(
          state.user_context_pid,
          state.tab_id,
          expression,
          timeout_ms,
          bidi_opts(state)
        )
      end)

    with {:ok, result} <- evaluate_result,
         {:ok, json} <-
           Profiling.measure({:browser_elixir, :decode_remote_json}, fn -> decode_remote_json(result) end) do
      {:ok, maybe_record_js_timing(json)}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  defp decode_remote_json(%{"result" => %{"type" => "string", "value" => payload}}) when is_binary(payload) do
    case JSON.decode(payload) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "invalid json payload from browser: #{inspect(reason)}"}
    end
  end

  defp decode_remote_json(result) do
    {:error, "unexpected script.evaluate result: #{inspect(result)}"}
  end

  defp maybe_record_js_timing(%{"jsTiming" => timings} = payload) when is_map(timings) do
    Enum.each(timings, fn
      {name, value} when is_binary(name) and is_number(value) and value >= 0 ->
        Profiling.record_us({:browser_js, name}, round(value * 1_000))

      _other ->
        :ok
    end)

    payload
  end

  defp maybe_record_js_timing(payload), do: payload

  defp await_driver_ready(state, timeout_ms \\ nil)

  defp await_driver_ready(state, nil) do
    await_driver_ready(state, state.ready_timeout_ms)
  end

  defp await_driver_ready(state, timeout_ms) when is_integer(timeout_ms) and timeout_ms <= 0 do
    {:ok, state,
     %{
       "ok" => true,
       "reason" => "timeout_skipped",
       "awaited" => [],
       "lastSignal" => "timeout_skipped",
       "lastLiveState" => "unknown",
       "timeoutMs" => timeout_ms
     }}
  end

  defp await_driver_ready(state, timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    started_at_ms = System.monotonic_time(:millisecond)
    retry_budget_ms = max(max(timeout_ms, state.ready_timeout_ms), @transient_ready_retry_min_budget_ms)
    do_await_driver_ready(state, started_at_ms, timeout_ms, retry_budget_ms)
  end

  defp do_await_driver_ready(state, started_at_ms, timeout_ms, retry_budget_ms)
       when is_integer(started_at_ms) and is_integer(timeout_ms) and timeout_ms > 0 and is_integer(retry_budget_ms) and
              retry_budget_ms > 0 do
    remaining_retry_ms = remaining_budget_ms(started_at_ms, retry_budget_ms)

    if remaining_retry_ms <= 0 do
      {:error, "browser readiness timeout", %{"ok" => false, "reason" => "timeout"}}
    else
      opts = await_ready_options(state, started_at_ms, timeout_ms)
      ready_result = await_ready_once(state, opts)

      handle_await_ready_result(
        state,
        ready_result,
        remaining_retry_ms,
        started_at_ms,
        timeout_ms,
        retry_budget_ms
      )
    end
  end

  defp await_ready_options(state, started_at_ms, timeout_ms) do
    attempt_timeout_ms = max(remaining_budget_ms(started_at_ms, timeout_ms), 1)
    quiet_ms = max(min(state.ready_quiet_ms, attempt_timeout_ms), 1)
    [timeout_ms: attempt_timeout_ms, quiet_ms: quiet_ms]
  end

  defp await_ready_once(state, opts) do
    Profiling.measure({:browser_wait, :await_ready}, fn ->
      UserContextProcess.await_ready(state.user_context_pid, opts, state.tab_id)
    end)
  end

  defp handle_await_ready_result(
         state,
         {:ok, readiness},
         _remaining_retry_ms,
         _started_at_ms,
         _timeout_ms,
         _retry_budget_ms
       ) do
    {:ok, state, readiness}
  end

  defp handle_await_ready_result(
         state,
         {:error, reason, details},
         remaining_retry_ms,
         started_at_ms,
         timeout_ms,
         retry_budget_ms
       ) do
    transient? = navigation_transition_error?(reason, details)

    retry_ctx = %{
      transient?: transient?,
      remaining_retry_ms: remaining_retry_ms,
      started_at_ms: started_at_ms,
      timeout_ms: timeout_ms,
      retry_budget_ms: retry_budget_ms
    }

    case normalize_await_ready_error(state, reason, details) do
      {:ok, readiness} ->
        {:ok, state, readiness}

      {:error, normalized_reason, normalized_details} ->
        maybe_retry_await_ready(state, reason, details, retry_ctx, {normalized_reason, normalized_details})
    end
  end

  defp maybe_retry_await_ready(
         state,
         reason,
         details,
         %{
           transient?: true,
           remaining_retry_ms: remaining_retry_ms,
           started_at_ms: started_at_ms,
           timeout_ms: timeout_ms,
           retry_budget_ms: retry_budget_ms
         },
         _normalized
       )
       when remaining_retry_ms > 0 do
    recovered_state = maybe_recover_transient_state(state, reason, details)
    Process.sleep(min(@transient_eval_retry_interval_ms, remaining_retry_ms))
    do_await_driver_ready(recovered_state, started_at_ms, timeout_ms, retry_budget_ms)
  end

  defp maybe_retry_await_ready(_state, _reason, _details, _retry_ctx, {normalized_reason, normalized_details}) do
    {:error, normalized_reason, normalized_details}
  end

  defp readiness_error(reason, readiness) do
    awaited = Map.get(readiness, "awaited", [])
    awaited_label = if is_list(awaited), do: Enum.join(awaited, ", "), else: inspect(awaited)
    last_signal = Map.get(readiness, "lastSignal", "unknown")
    live_state = Map.get(readiness, "lastLiveState", "unknown")

    "browser readiness failed: #{reason} (awaited: #{awaited_label}; last_signal: #{last_signal}; live_state: #{live_state})"
  end

  defp recoverable_action_readiness_error?(action, reason, readiness)
       when action in [:click, :submit] and is_binary(reason) and is_map(readiness) do
    reason == "browser readiness timeout" or navigation_transition_error?(reason, readiness)
  end

  defp recoverable_action_readiness_error?(_action, _reason, _readiness), do: false

  defp recoverable_visit_readiness_error?(reason, readiness)
       when reason in ["bidi command timeout", "browser readiness timeout"] and is_map(readiness) do
    readiness["reason"] == "timeout" and
      readiness["lastLiveState"] == "disconnected" and
      readiness["lastSignal"] == "liveview-disconnected" and
      is_binary(readiness["path"])
  end

  defp recoverable_visit_readiness_error?(_reason, _readiness), do: false

  defp navigation_transition_error?(reason, details) do
    combined = "#{reason} #{inspect(details)}"

    Enum.any?(@transient_navigation_eval_markers, &String.contains?(combined, &1))
  end

  defp maybe_recover_transient_state(state, reason, details) do
    if missing_context_error?(reason, details) do
      case UserContextProcess.recover_active_tab(state.user_context_pid, state.tab_id) do
        {:ok, recovered_tab_id} when is_binary(recovered_tab_id) and recovered_tab_id != "" ->
          %{state | tab_id: recovered_tab_id}

        _ ->
          state
      end
    else
      state
    end
  end

  defp missing_context_error?(reason, details) do
    combined = "#{reason} #{inspect(details)}"
    String.contains?(combined, "Cannot find context with specified id") or String.contains?(combined, "no such frame")
  end

  defp readiness_payload?(payload) when is_map(payload) do
    Map.has_key?(payload, "awaited") or Map.has_key?(payload, "lastSignal")
  end

  defp run_assertion_by_mode(:text, state, _locator, expected, visible, match_opts, timeout_ms, mode)
       when mode in [:assert, :refute] do
    run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode)
  end

  defp run_assertion_by_mode(:locator, state, locator, _expected, visible, match_opts, timeout_ms, mode)
       when mode in [:assert, :refute] do
    run_locator_assertion(state, locator, visible, match_opts, timeout_ms, mode)
  end

  defp run_value_assertion_by_mode(state, field_expected, match_opts, expected_value, timeout_ms, mode)
       when mode in [:assert, :refute] do
    started_at_ms = System.monotonic_time(:millisecond)

    do_run_value_assertion_by_mode(
      state,
      field_expected,
      match_opts,
      expected_value,
      timeout_ms,
      mode,
      started_at_ms
    )
  end

  defp do_run_value_assertion_by_mode(state, field_expected, match_opts, expected_value, timeout_ms, mode, started_at_ms) do
    remaining_timeout_ms = remaining_budget_ms(started_at_ms, timeout_ms)

    case resolve_form_field_value(state, field_expected, match_opts, remaining_timeout_ms) do
      {:ok, next_state, observed} ->
        matched? = value_matches?(observed.value, expected_value)

        cond do
          value_assertion_satisfied?(mode, matched?) ->
            {:ok, next_state, Map.put(observed, :expected, expected_value)}

          remaining_timeout_ms > 0 ->
            Process.sleep(min(@value_assertion_poll_interval_ms, remaining_timeout_ms))

            do_run_value_assertion_by_mode(
              next_state,
              field_expected,
              match_opts,
              expected_value,
              timeout_ms,
              mode,
              started_at_ms
            )

          true ->
            observed = Map.put(observed, :expected, expected_value)
            {:error, value_assertion_reason(mode), observed}
        end

      {:error, reason, next_state, observed} ->
        if reason == "no form field matched locator" and remaining_timeout_ms > 0 do
          Process.sleep(min(@value_assertion_poll_interval_ms, remaining_timeout_ms))

          do_run_value_assertion_by_mode(
            next_state,
            field_expected,
            match_opts,
            expected_value,
            timeout_ms,
            mode,
            started_at_ms
          )
        else
          {:error, reason, Map.put(observed, :expected, expected_value)}
        end
    end
  end

  defp resolve_form_field_value(state, field_expected, match_opts, timeout_ms) do
    eval_result =
      eval_json_with_transient_retry(state, timeout_ms, fn remaining_timeout_ms ->
        payload = build_action_payload(state, :fill_in, field_expected, match_opts, remaining_timeout_ms, %{})
        Expressions.action_resolve(payload)
      end)

    case eval_result do
      {:ok, %{"ok" => true, "target" => target} = result} when is_map(target) ->
        value = target |> Map.get("value") |> normalize_field_value()
        next_state = %{state | current_path: result["path"] || state.current_path}

        observed = %{
          path: next_state.current_path,
          field: target,
          value: value,
          candidate_values: [value]
        }

        {:ok, next_state, observed}

      {:ok, %{"ok" => false} = result} ->
        reason = action_failure_reason(:fill_in, match_opts, result, "no form field matched locator")
        next_state = %{state | current_path: result["path"] || state.current_path}

        observed = %{
          path: next_state.current_path,
          reason: Map.get(result, "reason"),
          match_count: Map.get(result, "matchCount"),
          candidate_count: Map.get(result, "candidateCount"),
          candidate_values: Map.get(result, "candidateValues", []),
          result: result
        }

        {:error, reason, next_state, observed}

      {:ok, result} ->
        observed = %{path: state.current_path, result: result}
        {:error, "unexpected value assertion payload", state, observed}

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, "failed to evaluate browser value assertion: #{reason}", state, observed}
    end
  end

  defp run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode) when mode in [:assert, :refute] do
    do_run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode)
  end

  defp do_run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode) do
    match_by = Keyword.get(match_opts, :match_by, :text)

    eval_result =
      eval_json_with_transient_retry(state, timeout_ms, fn remaining_timeout_ms ->
        payload =
          build_text_assertion_payload(state, expected, visible, match_opts, remaining_timeout_ms, mode, match_by)

        Expressions.text_assertion(payload)
      end)

    case eval_result do
      {:ok, result} ->
        next_state = %{state | current_path: result["path"] || state.current_path}
        observed = text_assertion_observed(result, expected, visible, match_by)

        case text_assertion_outcome(result, match_opts, mode) do
          :ok -> {:ok, next_state, observed}
          {:error, reason} -> {:error, reason, observed}
        end

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, "failed to evaluate browser text assertion: #{reason}", observed}
    end
  end

  defp run_locator_assertion(state, locator, visible, match_opts, timeout_ms, mode) when mode in [:assert, :refute] do
    do_run_locator_assertion(state, locator, visible, match_opts, timeout_ms, mode)
  end

  defp do_run_locator_assertion(state, locator, visible, match_opts, timeout_ms, mode) do
    eval_result =
      eval_json_with_transient_retry(state, timeout_ms, fn remaining_timeout_ms ->
        payload = build_locator_assertion_payload(state, locator, visible, match_opts, remaining_timeout_ms, mode)
        Expressions.locator_assertion(payload)
      end)

    case eval_result do
      {:ok, result} ->
        next_state = %{state | current_path: result["path"] || state.current_path}
        observed = locator_assertion_observed(result, locator, visible)

        case locator_assertion_outcome(result, match_opts, mode) do
          :ok -> {:ok, next_state, observed}
          {:error, reason} -> {:error, reason, observed}
        end

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, "failed to evaluate browser locator assertion: #{reason}", observed}
    end
  end

  defp build_text_assertion_payload(state, expected, visible, match_opts, timeout_ms, mode, match_by) do
    {between_min, between_max} = between_bounds(match_opts)

    %{
      scopeSelector: Session.scope(state),
      expected: text_expectation_payload(expected),
      exact: Keyword.get(match_opts, :exact, false),
      normalizeWs: Keyword.get(match_opts, :normalize_ws, true),
      matchBy: Atom.to_string(match_by),
      visibility: visibility_mode(visible),
      timeoutMs: timeout_ms,
      mode: Atom.to_string(mode),
      count: Keyword.get(match_opts, :count),
      min: Keyword.get(match_opts, :min),
      max: Keyword.get(match_opts, :max),
      betweenMin: between_min,
      betweenMax: between_max,
      pollMs: 250
    }
  end

  defp build_locator_assertion_payload(state, locator, visible, match_opts, timeout_ms, mode) do
    {between_min, between_max} = between_bounds(match_opts)

    %{
      scopeSelector: Session.scope(state),
      locator: locator_payload(locator),
      visibility: visibility_mode(visible),
      timeoutMs: timeout_ms,
      mode: Atom.to_string(mode),
      count: Keyword.get(match_opts, :count),
      min: Keyword.get(match_opts, :min),
      max: Keyword.get(match_opts, :max),
      betweenMin: between_min,
      betweenMax: between_max,
      pollMs: 250
    }
  end

  defp text_assertion_outcome(result, match_opts, mode) when mode in [:assert, :refute] do
    if Query.has_count_constraints?(match_opts) do
      match_count =
        case Map.get(result, "matchCount") do
          value when is_integer(value) and value >= 0 ->
            value

          _ ->
            result
            |> Map.get("matched", [])
            |> List.wrap()
            |> length()
        end

      Query.assertion_count_outcome(match_count, match_opts, mode)
    else
      if result["ok"] == true do
        :ok
      else
        {:error, text_assertion_reason(mode)}
      end
    end
  end

  defp locator_assertion_outcome(result, match_opts, mode) when mode in [:assert, :refute] do
    if Query.has_count_constraints?(match_opts) do
      match_count =
        case Map.get(result, "matchCount") do
          value when is_integer(value) and value >= 0 ->
            value

          _ ->
            result
            |> Map.get("matched", [])
            |> List.wrap()
            |> length()
        end

      Query.assertion_count_outcome(match_count, match_opts, mode)
    else
      if result["ok"] == true do
        :ok
      else
        {:error, locator_assertion_reason(mode)}
      end
    end
  end

  defp between_bounds(opts) do
    case Keyword.get(opts, :between) do
      {min, max} -> {min, max}
      _ -> {nil, nil}
    end
  end

  defp text_assertion_reason(:assert), do: "expected text not found"
  defp text_assertion_reason(:refute), do: "unexpected matching text found"
  defp locator_assertion_reason(:assert), do: "expected locator not found"
  defp locator_assertion_reason(:refute), do: "unexpected matching locator found"

  defp run_path_assertion(session, expected, opts, op) when op in [:assert_path, :refute_path] do
    state = state!(session)
    timeout_ms = path_timeout_ms(opts)
    exact = Keyword.fetch!(opts, :exact)
    expected_query = Cerberus.Path.normalize_expected_query(Keyword.get(opts, :query))

    expected_path =
      if is_binary(expected) do
        Cerberus.Path.normalize(expected) || expected
      else
        expected
      end

    expected_payload = path_expectation_payload(expected_path)

    do_run_path_assertion(session, state, expected, expected_query, exact, timeout_ms, op, expected_payload)
  end

  defp do_run_path_assertion(session, state, expected, expected_query, exact, timeout_ms, op, expected_payload) do
    eval_result =
      eval_json_with_transient_retry(state, timeout_ms, fn remaining_timeout_ms ->
        Expressions.path_assertion(expected_payload, expected_query, exact, op, remaining_timeout_ms, 100)
      end)

    case eval_result do
      {:ok, result} ->
        observed = %{
          path: result["path"] || state.current_path,
          scope: Session.scope(session),
          expected: expected,
          query: expected_query,
          exact: exact,
          timeout: timeout_ms,
          path_match?: result["path_match?"] == true,
          query_match?: result["query_match?"] == true
        }

        if result["ok"] == true do
          updated = %{session | current_path: observed.path}
          {:ok, updated, observed}
        else
          {:error, session, observed, "path assertion failed"}
        end

      {:error, reason, details} ->
        observed = %{
          path: state.current_path,
          scope: Session.scope(session),
          expected: expected,
          query: expected_query,
          exact: exact,
          timeout: timeout_ms,
          path_match?: false,
          query_match?: false,
          details: details
        }

        {:error, session, observed, "failed to evaluate browser path assertion: #{reason}"}
    end
  end

  defp text_assertion_observed(result, expected, visible, match_by) when is_map(result) do
    %{
      path: result["path"],
      title: result["title"] || "",
      visible: visible,
      match_by: match_by,
      texts: result["texts"] || [],
      matched: result["matched"] || [],
      expected: expected
    }
  end

  defp locator_assertion_observed(result, locator, visible) when is_map(result) do
    %{
      path: result["path"],
      title: result["title"] || "",
      visible: visible,
      texts: result["texts"] || [],
      matched: result["matched"] || [],
      expected: locator
    }
  end

  defp locator_assertion_requires_locator_engine?(%Locator{opts: locator_opts}) do
    Keyword.has_key?(locator_opts, :has) or
      Keyword.has_key?(locator_opts, :has_not) or
      Keyword.has_key?(locator_opts, :from) or
      Keyword.has_key?(locator_opts, :visible) or
      Keyword.has_key?(locator_opts, :checked) or
      Keyword.has_key?(locator_opts, :disabled) or
      Keyword.has_key?(locator_opts, :selected) or
      Keyword.has_key?(locator_opts, :readonly)
  end

  defp eval_json_transient_read(state, expression, timeout_ms \\ 0)

  defp eval_json_transient_read(state, expression, timeout_ms)
       when is_binary(expression) and is_integer(timeout_ms) and timeout_ms >= 0 do
    eval_json_with_transient_retry(state, timeout_ms, fn _remaining_timeout_ms -> expression end)
  end

  defp eval_json_with_transient_retry(state, timeout_ms, build_expression)
       when is_integer(timeout_ms) and timeout_ms >= 0 and is_function(build_expression, 1) do
    started_at_ms = System.monotonic_time(:millisecond)
    retry_budget_ms = max(timeout_ms, @transient_eval_retry_min_budget_ms)
    do_eval_json_with_transient_retry(state, started_at_ms, timeout_ms, retry_budget_ms, build_expression)
  end

  defp do_eval_json_with_transient_retry(state, started_at_ms, timeout_ms, retry_budget_ms, build_expression) do
    remaining_timeout_ms = remaining_budget_ms(started_at_ms, timeout_ms)
    expression = build_expression.(remaining_timeout_ms)

    case eval_json(state, expression, command_timeout_ms(remaining_timeout_ms)) do
      {:error, reason, details} = error ->
        remaining_retry_ms = remaining_budget_ms(started_at_ms, retry_budget_ms)

        if navigation_transition_error?(reason, details) and remaining_retry_ms > 0 do
          recovered_state = maybe_recover_transient_state(state, reason, details)
          Process.sleep(min(@transient_eval_retry_interval_ms, remaining_retry_ms))

          do_eval_json_with_transient_retry(
            recovered_state,
            started_at_ms,
            timeout_ms,
            retry_budget_ms,
            build_expression
          )
        else
          error
        end

      result ->
        result
    end
  end

  defp remaining_budget_ms(started_at_ms, budget_ms)
       when is_integer(started_at_ms) and is_integer(budget_ms) and budget_ms >= 0 do
    elapsed_ms = max(System.monotonic_time(:millisecond) - started_at_ms, 0)
    max(budget_ms - elapsed_ms, 0)
  end

  defp normalize_await_ready_error(state, reason, details) do
    readiness =
      if readiness_payload?(details) do
        details
      else
        merge_last_readiness(state, details)
      end

    if recoverable_readiness_timeout?(reason, readiness) do
      {:ok, Map.put_new(readiness, "recoveredFrom", reason)}
    else
      {:error, reason, readiness}
    end
  end

  defp merge_last_readiness(state, details) do
    readiness =
      case UserContextProcess.last_readiness(state.user_context_pid, state.tab_id) do
        %{} = last when map_size(last) > 0 -> last
        _ -> %{}
      end

    Map.put_new(readiness, "details", details)
  end

  defp recoverable_readiness_timeout?(reason, readiness)
       when reason in ["bidi command timeout", "browser readiness timeout"] and is_map(readiness) do
    readiness["ok"] == true and
      readiness["reason"] == "settled" and
      readiness["lastLiveState"] in ["connected", "down"]
  end

  defp recoverable_readiness_timeout?(_reason, _readiness), do: false

  defp state!(%__MODULE__{user_context_pid: user_context_pid, tab_id: tab_id} = state)
       when is_pid(user_context_pid) and is_binary(tab_id) do
    state
  end

  defp state!(_), do: raise(ArgumentError, "browser driver state is not initialized")

  defp validate_within_scope_snapshot(%{"ok" => true, "html" => html}) when is_binary(html), do: :ok

  defp validate_within_scope_snapshot(%{"ok" => false, "reason" => "cross_origin_frame"}) do
    {:error, "within/3 only supports same-origin iframes in browser mode"}
  end

  defp validate_within_scope_snapshot(%{"ok" => false, "reason" => reason}) when is_binary(reason) do
    {:error, "failed to resolve scoped roots: #{reason}"}
  end

  defp validate_within_scope_snapshot(_snapshot) do
    {:error, "browser scope snapshot returned an unexpected payload"}
  end

  defp build_within_scope_from_target(state, scope, snapshot, %{selector: selector, iframe?: true})
       when is_binary(selector) and selector != "" do
    with {:ok, iframe_result} <- eval_json_transient_read(state, Expressions.within_iframe_access(scope, selector)),
         :ok <- validate_within_iframe_access(iframe_result) do
      frame_chain = normalize_scope_frame_chain(snapshot)
      {:ok, %{frame_chain: frame_chain ++ [selector], selector: nil}}
    else
      {:error, reason, _details} ->
        {:error, "failed to inspect iframe access for within/3: #{reason}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_within_scope_from_target(_state, _scope, snapshot, %{selector: selector})
       when is_binary(selector) and selector != "" do
    frame_chain = normalize_scope_frame_chain(snapshot)
    {:ok, scope_from_parts(frame_chain, selector)}
  end

  defp build_within_scope_from_target(_state, _scope, _snapshot, _target) do
    {:error, "within locator matched element but a unique selector could not be derived"}
  end

  defp validate_within_iframe_access(%{"ok" => true, "sameOrigin" => true}), do: :ok

  defp validate_within_iframe_access(%{"ok" => true, "sameOrigin" => false}) do
    {:error, "within/3 only supports same-origin iframes in browser mode"}
  end

  defp validate_within_iframe_access(%{"ok" => false, "reason" => reason}) when is_binary(reason) do
    {:error, "failed to resolve iframe scope: #{reason}"}
  end

  defp validate_within_iframe_access(_result) do
    {:error, "iframe access check returned an unexpected payload"}
  end

  defp normalize_scope_frame_chain(snapshot) when is_map(snapshot) do
    snapshot
    |> Map.get("frameChain", [])
    |> List.wrap()
    |> Enum.filter(&(is_binary(&1) and String.trim(&1) != ""))
  end

  defp scope_from_parts([], selector), do: selector
  defp scope_from_parts(frame_chain, selector), do: %{frame_chain: frame_chain, selector: selector}

  defp update_session(%__MODULE__{} = session, %{} = state, op, observed) do
    %{
      session
      | user_context_pid: state.user_context_pid,
        tab_id: state.tab_id,
        browser_name: state.browser_name,
        base_url: state.base_url,
        assert_timeout_ms: state.assert_timeout_ms,
        ready_timeout_ms: state.ready_timeout_ms,
        ready_quiet_ms: state.ready_quiet_ms,
        browser_context_defaults: state.browser_context_defaults,
        active_form_selector: state.active_form_selector,
        scope: session.scope,
        current_path: state.current_path,
        last_result: LastResult.new(op, observed, session)
    }
  end

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp value_assertion_satisfied?(:assert, matched?), do: matched?
  defp value_assertion_satisfied?(:refute, matched?), do: not matched?

  defp value_assertion_reason(:assert), do: "expected field value not found"
  defp value_assertion_reason(:refute), do: "unexpected matching field value found"

  defp value_matches?(actual, %Regex{} = expected), do: Regex.match?(expected, actual)
  defp value_matches?(actual, expected) when is_binary(expected), do: actual == expected

  defp normalize_field_value(value) when is_binary(value), do: value
  defp normalize_field_value(value) when is_integer(value) or is_float(value), do: to_string(value)
  defp normalize_field_value(true), do: "true"
  defp normalize_field_value(false), do: "false"
  defp normalize_field_value([value | _rest]), do: normalize_field_value(value)
  defp normalize_field_value([]), do: ""
  defp normalize_field_value(nil), do: ""
  defp normalize_field_value(value), do: to_string(value)

  defp to_absolute_url(base_url, path_or_url) do
    uri = URI.parse(path_or_url)

    if is_binary(uri.scheme) do
      path_or_url
    else
      base_uri = URI.parse(base_url)
      base_uri |> URI.merge(path_or_url) |> to_string()
    end
  end

  defp html_snapshot!(%__MODULE__{} = session) do
    state = state!(session)

    case eval_json_transient_read(state, Expressions.browser_html()) do
      {:ok, payload} ->
        {state, Map.get(payload, "html", ""), Map.get(payload, "url")}

      {:error, reason, details} ->
        raise ArgumentError, "failed to collect browser HTML snapshot: #{reason} (#{inspect(details)})"
    end
  end

  defp snapshot_base_url(default_base_url, url) when is_binary(url) do
    uri = URI.parse(url)

    if is_binary(uri.scheme) and is_binary(uri.host) do
      port_suffix =
        case uri.port do
          nil -> ""
          80 when uri.scheme == "http" -> ""
          443 when uri.scheme == "https" -> ""
          port -> ":" <> Integer.to_string(port)
        end

      uri.scheme <> "://" <> uri.host <> port_suffix
    else
      default_base_url
    end
  rescue
    _ -> default_base_url
  end

  defp snapshot_base_url(default_base_url, _url), do: default_base_url

  defp capture_screenshot(context_id, full_page, bidi_opts) do
    params = maybe_full_page_origin(%{"context" => context_id}, full_page)

    BiDi.command("browsingContext.captureScreenshot", params, bidi_opts)
  end

  defp bidi_opts(%{bidi_opts: bidi_opts, browser_name: browser_name}) when is_list(bidi_opts) do
    Keyword.put_new(bidi_opts, :browser_name, browser_name)
  end

  defp bidi_opts(%{browser_name: browser_name}), do: [browser_name: browser_name]

  defp maybe_full_page_origin(params, true), do: Map.put(params, "origin", "document")
  defp maybe_full_page_origin(params, _full_page), do: params

  defp write_screenshot!(path, encoded_data) when is_binary(path) and is_binary(encoded_data) do
    File.mkdir_p!(Path.dirname(path))

    case Base.decode64(encoded_data) do
      {:ok, data} ->
        File.write!(path, data)

      :error ->
        raise ArgumentError, "failed to decode browser screenshot payload"
    end
  end

  @doc false
  @spec screenshot_path(keyword()) :: String.t()
  def screenshot_path(opts) when is_list(opts), do: Config.screenshot_path(opts)

  @doc false
  @spec screenshot_full_page(keyword()) :: boolean()
  def screenshot_full_page(opts) when is_list(opts), do: Config.screenshot_full_page(opts)

  defp start_user_context(opts) do
    case Process.whereis(@user_context_supervisor) do
      nil ->
        UserContextProcess.start_link(opts)

      supervisor_pid ->
        DynamicSupervisor.start_child(supervisor_pid, {UserContextProcess, opts})
    end
  end

  defp session_bidi_opts(opts, browser_name) when is_list(opts) and is_atom(browser_name) do
    opts
    |> Keyword.delete(:owner)
    |> Keyword.delete(:browser_context_defaults)
    |> Keyword.delete(:browser_name)
    |> Keyword.put(:browser_name, browser_name)
  end

  @doc false
  @spec browser_context_defaults(keyword()) :: browser_context_defaults()
  def browser_context_defaults(opts \\ []) when is_list(opts), do: Config.browser_context_defaults(opts)

  @doc false
  @spec ready_timeout_ms(keyword()) :: pos_integer()
  def ready_timeout_ms(opts) when is_list(opts), do: Config.ready_timeout_ms(opts)

  defp ready_quiet_ms(opts), do: Config.ready_quiet_ms(opts)

  defp visibility_filter(opts), do: Config.visibility_filter(opts)

  defp assertion_visibility(opts, %Locator{opts: locator_opts}) do
    case Keyword.get(locator_opts, :visible) do
      value when is_boolean(value) -> value
      _ -> visibility_filter(opts)
    end
  end

  defp assertion_timeout_ms(opts), do: Config.assertion_timeout_ms(opts)
  defp path_timeout_ms(opts), do: Config.path_timeout_ms(opts)

  defp action_timeout_ms(opts, fallback_timeout_ms)
       when is_list(opts) and is_integer(fallback_timeout_ms) and fallback_timeout_ms > 0 do
    case Keyword.fetch(opts, :timeout) do
      {:ok, timeout_ms} when is_integer(timeout_ms) and timeout_ms >= 0 ->
        timeout_ms

      _other ->
        fallback_timeout_ms
    end
  end

  defp command_timeout_ms(timeout_ms), do: Config.command_timeout_ms(timeout_ms)
  defp text_expectation_payload(expected), do: Config.text_expectation_payload(expected)
  defp path_expectation_payload(expected), do: Config.path_expectation_payload(expected)
  defp visibility_mode(visible), do: Config.visibility_mode(visible)

  defp restore_scope!(%{__struct__: _} = session, previous_scope) do
    Session.with_scope(session, previous_scope)
  end

  defp restore_scope!(_value, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp ensure_popup_mode_supported!(browser_name, popup_mode),
    do: Config.ensure_popup_mode_supported!(browser_name, popup_mode)
end
