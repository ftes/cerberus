defmodule Cerberus.Driver.Browser do
  @moduledoc false

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Config
  alias Cerberus.Driver.Browser.Expressions
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
  alias Cerberus.UploadFile

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @user_context_supervisor Cerberus.Driver.Browser.UserContextSupervisor
  @empty_browser_context_defaults %{viewport: nil, user_agent: nil, init_scripts: [], popup_mode: :allow}
  @clickable_match_field_by %{title: "title", alt: "alt", testid: "testid"}
  @field_match_field_by %{placeholder: "placeholder", title: "title", testid: "testid"}
  @action_failure_reason_messages %{
    "submit_target_failed" => "no submit button matched locator",
    "field_fill_failed" => "no form field matched locator",
    "field_not_select" => "matched field is not a select element",
    "field_not_radio" => "matched field is not a radio input",
    "field_not_checkbox" => "matched field is not a checkbox",
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
          base_url: String.t(),
          assert_timeout_ms: non_neg_integer(),
          ready_timeout_ms: pos_integer(),
          ready_quiet_ms: pos_integer(),
          browser_context_defaults: browser_context_defaults(),
          sandbox_metadata: String.t() | nil,
          scope: Session.scope_value(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct user_context_pid: nil,
            tab_id: nil,
            browser_name: :chrome,
            base_url: nil,
            assert_timeout_ms: 0,
            ready_timeout_ms: @default_ready_timeout_ms,
            ready_quiet_ms: @default_ready_quiet_ms,
            browser_context_defaults: @empty_browser_context_defaults,
            sandbox_metadata: nil,
            scope: nil,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    owner = self()
    context_defaults = browser_context_defaults(opts)
    browser_name = Runtime.browser_name(opts)
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

    maybe_configure_sandbox_metadata!(user_context_pid, opts)

    tab_id =
      case UserContextProcess.active_tab(user_context_pid) do
        value when is_binary(value) -> value
        _ -> raise ArgumentError, "failed to initialize browser driver: missing active tab"
      end

    %__MODULE__{
      user_context_pid: user_context_pid,
      tab_id: tab_id,
      browser_name: browser_name,
      base_url: base_url,
      assert_timeout_ms: Session.assert_timeout_from_opts!(opts, Session.live_browser_assert_timeout_default_ms()),
      ready_timeout_ms: ready_timeout_ms(opts),
      ready_quiet_ms: ready_quiet_ms(opts),
      browser_context_defaults: context_defaults,
      sandbox_metadata: Keyword.get(opts, :sandbox_metadata)
    }
  end

  @spec open_tab(t()) :: t()
  def open_tab(%__MODULE__{} = session) do
    case UserContextProcess.open_tab(session.user_context_pid) do
      {:ok, tab_id} ->
        %{
          session
          | tab_id: tab_id,
            scope: nil,
            current_path: nil
        }

      {:error, reason, details} ->
        raise ArgumentError, "failed to open browser tab: #{reason} (#{inspect(details)})"
    end
  end

  @spec switch_tab(t(), t()) :: t()
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

  @spec close_tab(t()) :: t()
  def close_tab(%__MODULE__{} = session) do
    case UserContextProcess.close_tab(session.user_context_pid, session.tab_id) do
      :ok ->
        next_tab_id = UserContextProcess.active_tab(session.user_context_pid)

        if is_binary(next_tab_id) do
          %{
            session
            | tab_id: next_tab_id,
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
    state = state!(session)

    case eval_json(state, Expressions.browser_html()) do
      {:ok, payload} ->
        html = Map.get(payload, "html", "")
        url = Map.get(payload, "url")
        path = OpenBrowser.write_snapshot!(html, snapshot_base_url(state.base_url, url))
        _ = open_fun.(path)
        session

      {:error, reason, details} ->
        raise ArgumentError, "failed to collect browser HTML snapshot: #{reason} (#{inspect(details)})"
    end
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

    case eval_json(state, Expressions.current_path()) do
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

    with {:ok, snapshot} <- eval_json(state, Expressions.within_scope_snapshot(scope)),
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

  @doc false
  @spec assert_path(t(), String.t() | Regex.t(), Options.path_opts()) ::
          {:ok, t(), map()} | {:error, t(), map(), String.t()}
  def assert_path(%__MODULE__{} = session, expected, opts) when is_binary(expected) or is_struct(expected, Regex) do
    run_path_assertion(session, expected, opts, :assert_path)
  end

  @doc false
  @spec refute_path(t(), String.t() | Regex.t(), Options.path_opts()) ::
          {:ok, t(), map()} | {:error, t(), map(), String.t()}
  def refute_path(%__MODULE__{} = session, expected, opts) when is_binary(expected) or is_struct(expected, Regex) do
    run_path_assertion(session, expected, opts, :refute_path)
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
        snapshot_after_visit!(session, state)

      {:error, reason, details} ->
        handle_visit_navigation_error!(session, state, reason, details)
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.click(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    if requires_snapshot_matching?(match_opts) do
      with_driver_ready(session, state, :click, fn ready_state ->
        do_click_with_snapshot(session, ready_state, expected, match_opts, selector)
      end)
    else
      with_driver_ready(session, state, :click, fn ready_state ->
        do_resolved_click(session, ready_state, expected, match_opts)
      end)
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{} = locator, value, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :fill_in, fn ready_state ->
        do_fill_in_with_snapshot(session, ready_state, expected, value, match_opts, selector)
      end)
    else
      do_resolved_fill_in(session, state, expected, value, match_opts)
    end
  end

  @impl true
  def select(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    option = Keyword.fetch!(opts, :option)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :select, fn ready_state ->
        do_select_with_snapshot(session, ready_state, expected, option, match_opts, selector)
      end)
    else
      do_resolved_select(session, state, expected, option, match_opts)
    end
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :choose, fn ready_state ->
        do_choose_with_snapshot(session, ready_state, expected, match_opts, selector)
      end)
    else
      do_resolved_choose(session, state, expected, match_opts)
    end
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :check, fn ready_state ->
        do_toggle_checkbox_with_snapshot(session, ready_state, expected, match_opts, selector, true, :check)
      end)
    else
      do_resolved_toggle_checkbox(session, state, expected, match_opts, true, :check)
    end
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :uncheck, fn ready_state ->
        do_toggle_checkbox_with_snapshot(session, ready_state, expected, match_opts, selector, false, :uncheck)
      end)
    else
      do_resolved_toggle_checkbox(session, state, expected, match_opts, false, :uncheck)
    end
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{} = locator, path, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :upload, fn ready_state ->
        do_upload_with_snapshot(session, ready_state, expected, path, match_opts, selector)
      end)
    else
      do_resolved_upload(session, state, expected, path, match_opts)
    end
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{} = locator, opts) do
    state = state!(session)
    {expected, match_opts} = LocatorOps.submit(locator, opts)

    if requires_snapshot_matching?(match_opts) do
      selector = Keyword.get(match_opts, :selector)

      with_driver_ready(session, state, :submit, fn ready_state ->
        do_submit_with_snapshot(session, ready_state, expected, match_opts, selector)
      end)
    else
      with_driver_ready(session, state, :submit, fn ready_state ->
        do_resolved_submit(session, ready_state, expected, match_opts)
      end)
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    timeout_ms = assertion_timeout_ms(opts)
    match_opts = locator_match_opts(locator, Keyword.delete(opts, :timeout))
    visible = visibility_filter(opts)

    case run_text_assertion(state, expected, visible, match_opts, timeout_ms, :assert) do
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
    visible = visibility_filter(opts)

    case run_text_assertion(state, expected, visible, match_opts, timeout_ms, :refute) do
      {:ok, next_state, observed} ->
        {:ok, update_session(session, next_state, :refute_has, observed), observed}

      {:error, reason, observed} ->
        {:error, session, observed, reason}
    end
  end

  defp do_click_with_snapshot(session, state, expected, opts, selector) do
    case clickables(state, selector) do
      {:ok, clickables_data} ->
        do_click(session, state, clickables_data, expected, opts, selector)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect clickable elements: #{reason}"}
    end
  end

  defp do_fill_in_with_snapshot(session, state, expected, value, opts, selector) do
    case form_fields(state, selector) do
      {:ok, fields_data} ->
        do_fill_in(session, state, fields_data, expected, value, opts, selector)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect form fields: #{reason}"}
    end
  end

  defp do_select_with_snapshot(session, state, expected, option, opts, selector) do
    case form_fields(state, selector) do
      {:ok, fields_data} ->
        do_select(session, state, fields_data, expected, option, opts, selector)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect form fields: #{reason}"}
    end
  end

  defp do_choose_with_snapshot(session, state, expected, opts, selector) do
    case form_fields(state, selector) do
      {:ok, fields_data} ->
        do_choose_radio(session, state, fields_data, expected, opts, selector)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect form fields: #{reason}"}
    end
  end

  defp do_toggle_checkbox_with_snapshot(session, state, expected, opts, selector, checked?, op) do
    case form_fields(state, selector) do
      {:ok, fields_data} ->
        do_toggle_checkbox(session, state, fields_data, expected, opts, selector, checked?, op)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect form fields: #{reason}"}
    end
  end

  defp do_upload_with_snapshot(session, state, expected, path, opts, selector) do
    case file_fields(state, selector) do
      {:ok, fields_data} ->
        do_upload(session, state, fields_data, expected, path, opts, selector)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect upload fields: #{reason}"}
    end
  end

  defp do_submit_with_snapshot(session, state, expected, opts, selector) do
    case clickables(state, selector) do
      {:ok, clickables_data} ->
        do_submit(session, state, clickables_data, expected, opts, selector)

      {:error, reason, details} ->
        observed = %{path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect submit controls: #{reason}"}
    end
  end

  defp do_resolved_click(session, state, expected, opts) do
    kind = Keyword.get(opts, :kind, :any)

    case perform_action(session, state, :click, expected, opts) do
      {:ok, %{"target" => target} = result} when is_map(target) ->
        click_target_result(session, state, target, result)

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
        submit_result(session, state, button, result)

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

    case perform_action(session, state, :select, expected, opts, %{option: option_values, exactOption: exact_option}) do
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
    timeout_ms = state.ready_timeout_ms
    payload = build_action_payload(state, op, expected, opts, extra_payload)

    with :ok <- maybe_ensure_action_helpers(state),
         {:ok, result} <- eval_json(state, Expressions.action_perform(payload), command_timeout_ms(timeout_ms)) do
      action_perform_result(session, state, op, opts, result)
    else
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

  defp build_action_payload(state, op, expected, opts, extra_payload) when is_list(opts) and is_map(extra_payload) do
    timeout_ms = state.ready_timeout_ms
    {between_min, between_max} = between_bounds(opts)

    Map.merge(
      %{
        op: Atom.to_string(op),
        scopeSelector: Session.scope(state),
        selector: Keyword.get(opts, :selector),
        locator: action_locator_payload(opts),
        expected: text_expectation_payload(expected),
        exact: Keyword.get(opts, :exact, false),
        normalizeWs: Keyword.get(opts, :normalize_ws, true),
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
        readyTimeoutMs: state.ready_timeout_ms,
        timeoutMs: timeout_ms,
        pollMs: 100
      },
      extra_payload
    )
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

  defp locator_payload(%Locator{kind: kind, value: members, opts: opts}) when kind in [:and, :or] do
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
      exact: Keyword.get(opts, :exact),
      normalizeWs: Keyword.get(opts, :normalize_ws),
      selector: Keyword.get(opts, :selector),
      has: nested_locator_payload(Keyword.get(opts, :has)),
      checked: Keyword.get(opts, :checked),
      disabled: Keyword.get(opts, :disabled),
      selected: Keyword.get(opts, :selected),
      readonly: Keyword.get(opts, :readonly)
    }
  end

  defp nested_locator_payload(%Locator{} = locator), do: locator_payload(locator)
  defp nested_locator_payload(_other), do: nil

  defp inspect_failure_prefix(op) when op in [:click], do: "failed to inspect clickable elements"
  defp inspect_failure_prefix(op) when op in [:submit], do: "failed to inspect submit controls"
  defp inspect_failure_prefix(op) when op in [:upload], do: "failed to inspect upload fields"
  defp inspect_failure_prefix(_op), do: "failed to inspect form fields"

  defp requires_snapshot_matching?(_opts) do
    false
  end

  defp do_click(session, state, clickables_data, expected, opts, selector) do
    kind = Keyword.get(opts, :kind, :any)
    links = Map.get(clickables_data, "links", [])
    buttons = Map.get(clickables_data, "buttons", [])
    link = maybe_matching_clickable(kind, :button, links, expected, opts)

    case link do
      nil ->
        case maybe_matching_clickable(kind, :link, buttons, expected, opts) do
          nil ->
            observed = %{action: :click, path: state.current_path, clickables: clickables_data}
            {:error, session, observed, no_clickable_error(kind)}

          button ->
            click_button(session, state, button, selector)
        end

      found_link ->
        click_link(session, state, found_link)
    end
  end

  defp do_submit(session, state, clickables_data, expected, opts, selector) do
    buttons =
      clickables_data
      |> Map.get("buttons", [])
      |> Enum.filter(&submit_control?/1)

    case find_matching_clickable(buttons, expected, opts) do
      {:error, reason} ->
        observed = %{action: :submit, path: state.current_path, clickables: clickables_data}
        {:error, session, observed, reason}

      {:ok, button} ->
        submit_button(session, state, button, selector)
    end
  end

  defp do_fill_in(session, state, fields_data, expected, value, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_field(fields, expected, opts) do
      {:error, reason} ->
        observed = %{action: :fill_in, path: state.current_path, fields: fields_data}
        {:error, session, observed, reason}

      {:ok, field} ->
        fill_field(session, state, field, value, selector)
    end
  end

  defp do_select(session, state, fields_data, expected, option, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_field(fields, expected, opts) do
      {:error, reason} ->
        observed = %{action: :select, path: state.current_path, fields: fields_data, option: option}
        {:error, session, observed, reason}

      {:ok, field} ->
        cond do
          not select_field?(field) ->
            observed = %{action: :select, path: state.current_path, field: field, option: option}
            {:error, session, observed, "matched field is not a select element"}

          field_disabled?(field) ->
            observed = %{action: :select, path: state.current_path, field: field, option: option}
            {:error, session, observed, "matched select field is disabled"}

          true ->
            exact_option = Keyword.get(opts, :exact_option, true)
            select_field_option(session, state, field, option, exact_option, selector)
        end
    end
  end

  defp do_choose_radio(session, state, fields_data, expected, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_field(fields, expected, opts) do
      {:error, reason} ->
        observed = %{action: :choose, path: state.current_path, fields: fields_data}
        {:error, session, observed, reason}

      {:ok, field} ->
        cond do
          not radio_field?(field) ->
            observed = %{action: :choose, path: state.current_path, field: field}
            {:error, session, observed, "matched field is not a radio input"}

          field_disabled?(field) ->
            observed = %{action: :choose, path: state.current_path, field: field}
            {:error, session, observed, "matched field is disabled"}

          true ->
            choose_radio_field(session, state, field, selector)
        end
    end
  end

  defp do_upload(session, state, fields_data, expected, path, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_field(fields, expected, opts) do
      {:error, reason} ->
        observed = %{action: :upload, path: state.current_path, fields: fields_data, file_path: path}
        {:error, session, observed, reason}

      {:ok, field} ->
        upload_field(session, state, field, path, selector)
    end
  end

  defp do_toggle_checkbox(session, state, fields_data, expected, opts, selector, checked?, op) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_field(fields, expected, opts) do
      {:error, reason} ->
        observed = %{action: op, path: state.current_path, fields: fields_data}
        {:error, session, observed, reason}

      {:ok, field} ->
        if checkbox_field?(field) do
          toggle_checkbox_field(session, state, field, checked?, selector, op)
        else
          observed = %{action: op, path: state.current_path, field: field}
          {:error, session, observed, "matched field is not a checkbox"}
        end
    end
  end

  defp upload_field(session, state, field, path, selector) do
    file = UploadFile.read!(path)
    index = field["index"] || 0

    expression =
      Expressions.upload_field(
        index,
        file.file_name,
        file.mime_type,
        file.last_modified_unix_ms,
        file.content,
        Session.scope(state),
        selector
      )

    case eval_json(state, expression) do
      {:ok, result} ->
        upload_field_result(session, state, field, file.file_name, result)

      {:error, reason, details} ->
        observed = %{action: :upload, path: state.current_path, field: field, file_path: path, details: details}
        {:error, session, observed, "browser upload failed: #{reason}"}
    end
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{action: :upload, path: state.current_path, field: field, file_path: path}
      {:error, session, observed, Exception.message(error)}
  end

  defp upload_field_result(session, state, field, file_name, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        case snapshot_with_retry(state) do
          {next_state, snapshot} ->
            observed = %{
              action: :upload,
              path: snapshot.path,
              title: snapshot.title,
              field: field,
              file_name: file_name,
              readiness: readiness
            }

            {:ok, update_session(session, next_state, :upload, observed), observed}

          {:error, reason, details} ->
            observed = %{
              action: :upload,
              path: Map.get(result, "path", state.current_path),
              field: field,
              file_name: file_name,
              readiness: readiness,
              details: details
            }

            {:error, session, observed, "failed to inspect page after upload: #{reason}"}
        end

      {:error, reason, readiness} ->
        observed = %{
          action: :upload,
          path: state.current_path,
          field: field,
          file_name: file_name,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp upload_field_result(session, state, field, file_name, result) do
    reason = Map.get(result, "reason", "upload_failed")
    observed = %{action: :upload, path: state.current_path, field: field, file_name: file_name, result: result}
    {:error, session, observed, "browser upload failed: #{reason}"}
  end

  defp click_link(session, state, link) do
    url = link["resolvedHref"] || link["href"] || ""

    if url == "" do
      observed = %{action: :link, path: state.current_path, clicked: link["text"], link: link}
      {:error, session, observed, "matched link has no href"}
    else
      navigate_link(session, state, link, url)
    end
  end

  defp click_target_result(session, state, target, result) when is_map(target) and is_map(result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        path =
          result
          |> action_result_path(state.current_path)
          |> ready_path(readiness)

        next_state = %{state | current_path: path}

        observed = %{
          action: :click,
          clicked: target["text"],
          path: path,
          target: target,
          readiness: readiness
        }

        {:ok, update_session(session, next_state, :click, observed), observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :click,
          clicked: target["text"],
          path: state.current_path,
          target: target,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp submit_result(session, state, button, result) when is_map(result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        path =
          result
          |> action_result_path(state.current_path)
          |> ready_path(readiness)

        next_state = %{state | current_path: path}

        observed = %{
          action: :submit,
          clicked: button["text"],
          path: path,
          target: button,
          readiness: readiness
        }

        {:ok, update_session(session, next_state, :submit, observed), observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :submit,
          clicked: button["text"],
          path: state.current_path,
          target: button,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp fill_in_result(session, state, field, value, result) when is_map(result) do
    path = action_result_path(result, state.current_path)
    next_state = %{state | current_path: path}

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
    next_state = %{state | current_path: path}

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
    next_state = %{state | current_path: path}

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
    next_state = %{state | current_path: path}

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
    next_state = %{state | current_path: path}

    observed = %{
      action: :upload,
      path: path,
      field: field,
      file_name: file_name
    }

    {:ok, update_session(session, next_state, :upload, observed), observed}
  end

  defp submit_button(session, state, button, selector) do
    index = button["index"] || 0
    expression = Expressions.button_click(index, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, %{"ok" => true}} ->
        submit_after_eval(session, state, button)

      {:ok, result} ->
        reason = Map.get(result, "reason", "submit_target_failed")
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, result: result}
        {:error, session, observed, "browser submit failed: #{reason}"}

      {:error, reason, details} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser submit failed: #{reason}"}
    end
  end

  defp submit_after_eval(session, state, button) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        submit_snapshot_result(session, state, button, readiness)

      {:error, reason, readiness} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, readiness: readiness}
        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp submit_snapshot_result(session, state, button, readiness) do
    case snapshot_with_retry(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :submit,
          clicked: button["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden,
          readiness: readiness
        }

        {:ok, update_session(session, next_state, :submit, observed), observed}

      {:error, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button["text"],
          path: state.current_path,
          details: details,
          readiness: readiness
        }

        {:error, session, observed, "failed to inspect page after submit: #{reason}"}
    end
  end

  defp fill_field(session, state, field, value, selector) do
    index = field["index"] || 0
    expression = Expressions.field_set(index, value, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, result} ->
        fill_field_result(session, state, field, value, result)

      {:error, reason, details} ->
        observed = %{action: :fill_in, path: state.current_path, field: field, details: details}
        {:error, session, observed, "browser field fill failed: #{reason}"}
    end
  end

  defp toggle_checkbox_field(session, state, field, checked?, selector, op) do
    index = field["index"] || 0
    expression = Expressions.checkbox_set(index, checked?, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, result} ->
        toggle_checkbox_result(session, state, field, checked?, op, result)

      {:error, reason, details} ->
        observed = %{action: op, path: state.current_path, field: field, checked: checked?, details: details}
        {:error, session, observed, "browser checkbox toggle failed: #{reason}"}
    end
  end

  defp select_field_option(session, state, field, option, exact_option, selector) do
    index = field["index"] || 0
    options = List.wrap(option)

    expression =
      Expressions.select_set(
        index,
        options,
        exact_option,
        Session.scope(state),
        selector
      )

    case eval_json(state, expression) do
      {:ok, result} ->
        select_field_result(session, state, field, option, result)

      {:error, reason, details} ->
        observed = %{action: :select, path: state.current_path, field: field, option: option, details: details}
        {:error, session, observed, "browser select failed: #{reason}"}
    end
  end

  defp choose_radio_field(session, state, field, selector) do
    index = field["index"] || 0
    expression = Expressions.radio_set(index, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, result} ->
        choose_radio_result(session, state, field, result)

      {:error, reason, details} ->
        observed = %{action: :choose, path: state.current_path, field: field, details: details}
        {:error, session, observed, "browser choose failed: #{reason}"}
    end
  end

  defp fill_field_result(session, state, field, value, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: :fill_in,
          path: Map.get(result, "path", state.current_path),
          field: field,
          value: value,
          readiness: readiness
        }

        {:ok, session, observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :fill_in,
          path: state.current_path,
          field: field,
          value: value,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp fill_field_result(session, state, field, _value, result) do
    reason = Map.get(result, "reason", "field_fill_failed")
    observed = %{action: :fill_in, path: state.current_path, field: field, result: result}
    {:error, session, observed, "browser field fill failed: #{reason}"}
  end

  defp toggle_checkbox_result(session, state, field, checked?, op, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: op,
          path: Map.get(result, "path", state.current_path),
          field: field,
          checked: checked?,
          readiness: readiness
        }

        {:ok, session, observed}

      {:error, reason, readiness} ->
        observed = %{
          action: op,
          path: state.current_path,
          field: field,
          checked: checked?,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp toggle_checkbox_result(session, state, field, checked?, op, result) do
    reason = Map.get(result, "reason", "checkbox_toggle_failed")
    observed = %{action: op, path: state.current_path, field: field, checked: checked?, result: result}
    {:error, session, observed, "browser checkbox toggle failed: #{reason}"}
  end

  defp select_field_result(session, state, field, option, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: :select,
          path: Map.get(result, "path", state.current_path),
          field: field,
          option: option,
          value: Map.get(result, "value"),
          readiness: readiness
        }

        {:ok, session, observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :select,
          path: state.current_path,
          field: field,
          option: option,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp select_field_result(session, state, field, option, result) do
    reason = Map.get(result, "reason", "select_failed")
    observed = %{action: :select, path: state.current_path, field: field, option: option, result: result}
    {:error, session, observed, "browser select failed: #{reason}"}
  end

  defp choose_radio_result(session, state, field, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: :choose,
          path: Map.get(result, "path", state.current_path),
          field: field,
          value: Map.get(result, "value"),
          readiness: readiness
        }

        {:ok, session, observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :choose,
          path: state.current_path,
          field: field,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp choose_radio_result(session, state, field, result) do
    reason = Map.get(result, "reason", "choose_failed")
    observed = %{action: :choose, path: state.current_path, field: field, result: result}
    {:error, session, observed, "browser choose failed: #{reason}"}
  end

  defp navigate_link(session, state, link, url) do
    case navigate_browser(state, url) do
      {:ok, result} ->
        path = navigation_path(result, url, state.current_path)
        next_state = %{state | current_path: path}

        observed = %{
          action: :link,
          clicked: link["text"],
          path: path
        }

        {:ok, update_session(session, next_state, :click, observed), observed}

      {:error, reason, details} ->
        observed = %{action: :link, clicked: link["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser link navigation failed: #{reason}"}
    end
  end

  defp navigation_path(%{"url" => url}, _fallback_url, current_path) when is_binary(url),
    do: path_from_url(url, current_path)

  defp navigation_path(_result, fallback_url, current_path), do: path_from_url(fallback_url, current_path)

  defp path_from_url(url, current_path) when is_binary(url) do
    case URI.parse(url) do
      %URI{path: path, query: query} when is_binary(path) and path != "" ->
        if is_binary(query) and query != "", do: path <> "?" <> query, else: path

      _ ->
        current_path
    end
  end

  defp action_result_path(%{"path" => path}, _fallback_path) when is_binary(path), do: path
  defp action_result_path(_result, fallback_path), do: fallback_path

  defp ready_path(path, %{"path" => ready_path}) when is_binary(path) and is_binary(ready_path) and ready_path != "" do
    ready_path
  end

  defp ready_path(path, _readiness) when is_binary(path), do: path

  defp find_matching_clickable(items, expected, opts) do
    matches =
      Enum.filter(items, fn item ->
        value = clickable_match_value(item, Keyword.get(opts, :match_by, :text))

        Query.match_text?(value, expected, opts) and Query.matches_state_filters?(item, opts) and
          matches_composition_filters?(item, opts)
      end)

    Query.pick_match(matches, opts)
  end

  defp maybe_matching_clickable(kind, skip_kind, _items, _expected, _opts) when kind == skip_kind, do: nil

  defp maybe_matching_clickable(_kind, _skip_kind, items, expected, opts) do
    case find_matching_clickable(items, expected, opts) do
      {:ok, item} -> item
      {:error, _reason} -> nil
    end
  end

  defp find_matching_field(items, expected, opts) do
    matches =
      Enum.filter(items, fn item ->
        value = field_match_value(item, Keyword.get(opts, :match_by, :label))

        Query.match_text?(value, expected, opts) and Query.matches_state_filters?(item, opts) and
          matches_composition_filters?(item, opts)
      end)

    Query.pick_match(matches, opts)
  end

  defp matches_composition_filters?(item, opts) do
    case Keyword.get(opts, :has) do
      nil ->
        true

      %Locator{} ->
        case item["outer_html"] do
          html when is_binary(html) and html != "" ->
            Html.fragment_matches_locator_filters?(html, opts)

          _ ->
            false
        end

      _other ->
        false
    end
  end

  defp clickable_match_value(item, match_by) when is_map(item),
    do: item[Map.get(@clickable_match_field_by, match_by, "text")] || ""

  defp field_match_value(item, :label) when is_map(item), do: item["label"] || ""

  defp field_match_value(item, match_by) when is_map(item),
    do: item[Map.get(@field_match_field_by, match_by, "label")] || ""

  defp submit_control?(button) do
    type = (button["type"] || "submit") |> to_string() |> String.downcase()
    type in ["submit", ""]
  end

  defp checkbox_field?(field) do
    (field["type"] || "") |> to_string() |> String.downcase() == "checkbox"
  end

  defp radio_field?(field) do
    (field["type"] || "") |> to_string() |> String.downcase() == "radio"
  end

  defp select_field?(field) do
    (field["tag"] || "") |> to_string() |> String.downcase() == "select"
  end

  defp field_disabled?(field) do
    field["disabled"] == true
  end

  defp click_button(session, state, button, selector) do
    index = button["index"] || 0
    expression = Expressions.button_click(index, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, _result} ->
        click_button_after_eval(session, state, button)

      {:error, reason, details} ->
        observed = %{action: :button, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser button click failed: #{reason}"}
    end
  end

  defp clickables(state, selector) do
    eval_json(state, Expressions.clickables(Session.scope(state), selector))
  end

  defp form_fields(state, selector) do
    eval_json(state, Expressions.form_fields(Session.scope(state), selector))
  end

  defp file_fields(state, selector) do
    eval_json(state, Expressions.file_fields(Session.scope(state), selector))
  end

  defp with_snapshot(state) do
    case eval_json(state, Expressions.snapshot(Session.scope(state))) do
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

  defp snapshot_after_visit!(session, state) do
    case with_snapshot(state) do
      {state, snapshot} ->
        update_session(session, state, :visit, %{path: snapshot.path, title: snapshot.title})

      {:error, reason, details} ->
        raise ArgumentError,
              "failed to collect browser snapshot after visit: #{reason} (#{inspect(details)})"
    end
  end

  defp handle_visit_navigation_error!(session, state, reason, details) do
    if navigate_interrupted_by_followup?(reason, details) do
      await_ready_after_navigation_interrupt!(state)
      snapshot_after_visit!(session, state)
    else
      raise ArgumentError, "browser navigate failed: #{reason} (#{inspect(details)})"
    end
  end

  defp await_ready_after_navigation_interrupt!(state) do
    case await_driver_ready(state) do
      {:ok, _readiness} ->
        :ok

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

  defp eval_json(state, expression, timeout_ms \\ 10_000)

  defp eval_json(state, expression, timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    evaluate_result =
      Profiling.measure({:browser_wait, :evaluate_with_timeout}, fn ->
        UserContextProcess.evaluate_with_timeout(state.user_context_pid, expression, timeout_ms, state.tab_id)
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

  defp with_driver_ready(session, state, action, on_ready) when is_function(on_ready, 1) do
    case await_driver_ready(state) do
      {:ok, _readiness} ->
        on_ready.(state)

      {:error, reason, readiness} ->
        observed = %{
          action: action,
          path: state.current_path,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp await_driver_ready(state) do
    opts = [timeout_ms: state.ready_timeout_ms, quiet_ms: state.ready_quiet_ms]

    ready_result =
      Profiling.measure({:browser_wait, :await_ready}, fn ->
        UserContextProcess.await_ready(state.user_context_pid, opts, state.tab_id)
      end)

    case ready_result do
      {:ok, readiness} ->
        {:ok, readiness}

      {:error, reason, details} ->
        normalize_await_ready_error(state, reason, details)
    end
  end

  defp readiness_error(reason, readiness) do
    awaited = Map.get(readiness, "awaited", [])
    awaited_label = if is_list(awaited), do: Enum.join(awaited, ", "), else: inspect(awaited)
    last_signal = Map.get(readiness, "lastSignal", "unknown")
    live_state = Map.get(readiness, "lastLiveState", "unknown")

    "browser readiness failed: #{reason} (awaited: #{awaited_label}; last_signal: #{last_signal}; live_state: #{live_state})"
  end

  defp navigation_transition_error?(reason, details) do
    combined = "#{reason} #{inspect(details)}"

    String.contains?(combined, "Inspected target navigated or closed") or
      String.contains?(combined, "Cannot find context with specified id") or
      String.contains?(combined, "execution contexts cleared")
  end

  defp readiness_payload?(payload) when is_map(payload) do
    Map.has_key?(payload, "awaited") or Map.has_key?(payload, "lastSignal")
  end

  defp run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode) when mode in [:assert, :refute] do
    do_run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode)
  end

  defp do_run_text_assertion(state, expected, visible, match_opts, timeout_ms, mode) do
    match_by = Keyword.get(match_opts, :match_by, :text)
    payload = build_text_assertion_payload(state, expected, visible, match_opts, timeout_ms, mode, match_by)
    expression = Expressions.text_assertion(payload)

    case eval_json(state, expression, command_timeout_ms(timeout_ms)) do
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

  defp build_text_assertion_payload(state, expected, visible, match_opts, timeout_ms, mode, match_by) do
    {between_min, between_max} = between_bounds(match_opts)

    %{
      scopeSelector: Session.scope(state),
      selector: Keyword.get(match_opts, :selector),
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

  defp between_bounds(opts) do
    case Keyword.get(opts, :between) do
      {min, max} -> {min, max}
      _ -> {nil, nil}
    end
  end

  defp text_assertion_reason(:assert), do: "expected text not found"
  defp text_assertion_reason(:refute), do: "unexpected matching text found"

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
    expression = Expressions.path_assertion(expected_payload, expected_query, exact, op, timeout_ms, 100)

    case eval_json(state, expression, command_timeout_ms(timeout_ms)) do
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

  defp maybe_ensure_action_helpers(_state), do: :ok

  defp click_button_after_eval(session, state, button) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        click_button_snapshot_result(session, state, button, readiness)

      {:error, reason, readiness} ->
        observed = %{
          action: :button,
          clicked: button["text"],
          path: state.current_path,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp click_button_snapshot_result(session, state, button, readiness) do
    case snapshot_with_retry(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :button,
          clicked: button["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden,
          readiness: readiness
        }

        {:ok, update_session(session, next_state, :click, observed), observed}

      {:error, reason, details} ->
        observed = %{
          action: :button,
          clicked: button["text"],
          path: state.current_path,
          details: details,
          readiness: readiness
        }

        {:error, session, observed, "failed to inspect page after button click: #{reason}"}
    end
  end

  defp normalize_await_ready_error(state, reason, details) do
    if navigation_transition_error?(reason, details) do
      {:ok, navigation_transition_readiness(details)}
    else
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
  end

  defp navigation_transition_readiness(details) do
    %{
      "ok" => true,
      "reason" => "navigation-transition",
      "awaited" => ["navigation-complete"],
      "lastSignal" => "bidi-navigation-transition",
      "lastLiveState" => "unknown",
      "details" => details
    }
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

  defp snapshot_with_retry(state, attempts \\ 6, delay_ms \\ 50)

  defp snapshot_with_retry(state, attempts, _delay_ms) when attempts <= 0 do
    with_snapshot(state)
  end

  defp snapshot_with_retry(state, attempts, delay_ms) do
    case with_snapshot(state) do
      {:error, reason, details} = error ->
        if navigation_transition_error?(reason, details) do
          Process.sleep(delay_ms)
          snapshot_with_retry(state, attempts - 1, delay_ms)
        else
          error
        end

      success ->
        success
    end
  end

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
    with {:ok, iframe_result} <- eval_json(state, Expressions.within_iframe_access(scope, selector)),
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
        sandbox_metadata: state.sandbox_metadata,
        scope: session.scope,
        current_path: state.current_path,
        last_result: %{op: op, observed: observed}
    }
  end

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp to_absolute_url(base_url, path_or_url) do
    uri = URI.parse(path_or_url)

    if is_binary(uri.scheme) do
      path_or_url
    else
      base_uri = URI.parse(base_url)
      base_uri |> URI.merge(path_or_url) |> to_string()
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

  @doc false
  @spec browser_context_defaults(keyword()) :: browser_context_defaults()
  def browser_context_defaults(opts \\ []) when is_list(opts), do: Config.browser_context_defaults(opts)

  defp maybe_configure_sandbox_metadata!(user_context_pid, opts) do
    case Keyword.get(opts, :sandbox_metadata) do
      nil ->
        :ok

      metadata when is_binary(metadata) ->
        if String.trim(metadata) == "" do
          raise ArgumentError, ":sandbox_metadata must be a non-empty string"
        end

        case UserContextProcess.set_user_agent(user_context_pid, metadata) do
          :ok ->
            :ok

          {:error, reason, details} ->
            raise ArgumentError,
                  "failed to configure browser sandbox metadata: #{reason} (#{inspect(details)})"
        end

      other ->
        raise ArgumentError, "expected :sandbox_metadata option to be a string, got: #{inspect(other)}"
    end
  end

  @doc false
  @spec ready_timeout_ms(keyword()) :: pos_integer()
  def ready_timeout_ms(opts) when is_list(opts), do: Config.ready_timeout_ms(opts)

  defp ready_quiet_ms(opts), do: Config.ready_quiet_ms(opts)

  defp visibility_filter(opts), do: Config.visibility_filter(opts)
  defp assertion_timeout_ms(opts), do: Config.assertion_timeout_ms(opts)
  defp path_timeout_ms(opts), do: Config.path_timeout_ms(opts)
  defp command_timeout_ms(timeout_ms), do: Config.command_timeout_ms(timeout_ms)
  defp text_expectation_payload(expected), do: Config.text_expectation_payload(expected)
  defp path_expectation_payload(expected), do: Config.path_expectation_payload(expected)
  defp visibility_mode(visible), do: Config.visibility_mode(visible)

  defp ensure_popup_mode_supported!(browser_name, popup_mode),
    do: Config.ensure_popup_mode_supported!(browser_name, popup_mode)
end
