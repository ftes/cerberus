defmodule Cerberus.Driver.Browser.Extensions do
  @moduledoc false

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Types
  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Profiling
  alias Cerberus.Query
  alias ExUnit.AssertionError

  @default_dialog_timeout_ms 1_500
  @default_popup_timeout_ms 1_500
  @default_download_timeout_ms 1_500
  @default_evaluate_timeout_ms 10_000
  @popup_task_poll_ms 10
  @transient_eval_retry_interval_ms 25
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
  @webdriver_key_values %{
    "Alt" => <<0xE00A::utf8>>,
    "AltLeft" => <<0xE00A::utf8>>,
    "AltRight" => <<0xE00A::utf8>>,
    "ArrowDown" => <<0xE015::utf8>>,
    "ArrowLeft" => <<0xE012::utf8>>,
    "ArrowRight" => <<0xE014::utf8>>,
    "ArrowUp" => <<0xE013::utf8>>,
    "Backquote" => "`",
    "Backslash" => "\\",
    "Backspace" => <<0xE003::utf8>>,
    "BracketLeft" => "[",
    "BracketRight" => "]",
    "Clear" => <<0xE005::utf8>>,
    "Comma" => ",",
    "Command" => <<0xE03D::utf8>>,
    "ContextMenu" => <<0xE03D::utf8>>,
    "Control" => <<0xE009::utf8>>,
    "ControlLeft" => <<0xE009::utf8>>,
    "ControlRight" => <<0xE009::utf8>>,
    "Delete" => <<0xE017::utf8>>,
    "Down" => <<0xE015::utf8>>,
    "End" => <<0xE010::utf8>>,
    "Enter" => <<0xE007::utf8>>,
    "Equal" => "=",
    "Escape" => <<0xE00C::utf8>>,
    "Esc" => <<0xE00C::utf8>>,
    "F1" => <<0xE031::utf8>>,
    "F2" => <<0xE032::utf8>>,
    "F3" => <<0xE033::utf8>>,
    "F4" => <<0xE034::utf8>>,
    "F5" => <<0xE035::utf8>>,
    "F6" => <<0xE036::utf8>>,
    "F7" => <<0xE037::utf8>>,
    "F8" => <<0xE038::utf8>>,
    "F9" => <<0xE039::utf8>>,
    "F10" => <<0xE03A::utf8>>,
    "F11" => <<0xE03B::utf8>>,
    "F12" => <<0xE03C::utf8>>,
    "Home" => <<0xE011::utf8>>,
    "Insert" => <<0xE016::utf8>>,
    "Left" => <<0xE012::utf8>>,
    "Meta" => <<0xE03D::utf8>>,
    "MetaLeft" => <<0xE03D::utf8>>,
    "MetaRight" => <<0xE03D::utf8>>,
    "Minus" => "-",
    "Numpad0" => "0",
    "Numpad1" => "1",
    "Numpad2" => "2",
    "Numpad3" => "3",
    "Numpad4" => "4",
    "Numpad5" => "5",
    "Numpad6" => "6",
    "Numpad7" => "7",
    "Numpad8" => "8",
    "Numpad9" => "9",
    "NumpadAdd" => "+",
    "NumpadDecimal" => ".",
    "NumpadDivide" => "/",
    "NumpadEnter" => <<0xE007::utf8>>,
    "NumpadMultiply" => "*",
    "NumpadSubtract" => "-",
    "Option" => <<0xE00A::utf8>>,
    "PageDown" => <<0xE00F::utf8>>,
    "PageUp" => <<0xE00E::utf8>>,
    "Period" => ".",
    "Plus" => "+",
    "Quote" => "'",
    "Return" => <<0xE006::utf8>>,
    "Right" => <<0xE014::utf8>>,
    "Semicolon" => ";",
    "Shift" => <<0xE008::utf8>>,
    "ShiftLeft" => <<0xE008::utf8>>,
    "ShiftRight" => <<0xE008::utf8>>,
    "Slash" => "/",
    "Space" => <<0xE00D::utf8>>,
    "Tab" => <<0xE004::utf8>>,
    "Up" => <<0xE013::utf8>>
  }
  @modifier_key_tokens MapSet.new([
                         "Alt",
                         "AltLeft",
                         "AltRight",
                         "Command",
                         "Control",
                         "ControlLeft",
                         "ControlRight",
                         "ControlOrMeta",
                         "Meta",
                         "MetaLeft",
                         "MetaRight",
                         "Option",
                         "Shift",
                         "ShiftLeft",
                         "ShiftRight"
                       ])

  @spec type(Browser.t(), String.t(), Options.browser_type_opts()) :: Browser.t()
  def type(%Browser{} = session, text, opts \\ []) when is_binary(text) and is_list(opts) do
    selector = selector_opt!(opts)
    clear? = Keyword.get(opts, :clear, false)
    timeout_ms = extension_timeout_ms(session, opts)

    with {:ok, %{"ok" => true}} <- evaluate_json(session, prepare_type_expression(selector, clear?), timeout_ms),
         :ok <- perform_keyboard_actions(session, type_actions(text), timeout_ms) do
      session
    else
      {:ok, payload} ->
        raise ArgumentError, "browser type failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser type failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec press(Browser.t(), String.t(), Options.browser_press_opts()) :: Browser.t()
  def press(%Browser{} = session, key, opts \\ []) when is_binary(key) and is_list(opts) do
    selector = selector_opt!(opts)
    timeout_ms = extension_timeout_ms(session, opts)

    with {:ok, %{"ok" => true}} <- evaluate_json(session, focus_expression(selector), timeout_ms),
         :ok <- perform_keyboard_actions(session, press_actions(key), timeout_ms) do
      session
    else
      {:ok, payload} ->
        raise ArgumentError, "browser press failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser press failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec drag(Browser.t(), String.t(), String.t(), Options.browser_drag_opts()) :: Browser.t()
  def drag(%Browser{} = session, source_selector, target_selector, opts \\ [])
      when is_binary(source_selector) and is_binary(target_selector) and is_list(opts) do
    source_selector = non_empty_selector!(source_selector, "drag/4 source selector")
    target_selector = non_empty_selector!(target_selector, "drag/4 target selector")
    timeout_ms = extension_timeout_ms(session, opts)

    case evaluate_json(session, drag_expression(source_selector, target_selector), timeout_ms) do
      {:ok, %{"ok" => true}} ->
        session

      {:ok, payload} ->
        raise ArgumentError, "browser drag failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser drag failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec assert_dialog(Browser.t(), Locator.t(), Options.browser_assert_dialog_opts()) :: Browser.t()
  def assert_dialog(%Browser{} = session, %Locator{} = locator, opts \\ []) when is_list(opts) do
    timeout_ms = dialog_timeout_ms(opts)
    dialog = await_open_dialog!(session, locator, timeout_ms)
    assert_dialog_text_match!(locator, dialog)
    ensure_dialog_auto_accepted!(session, timeout_ms, dialog)
    session
  end

  @spec with_popup(
          Browser.t(),
          (Browser.t() -> term()),
          (Browser.t(), Browser.t() -> term()),
          Options.browser_with_popup_opts()
        ) :: Browser.t()
  def with_popup(%Browser{} = session, trigger_fun, callback_fun, opts \\ [])
      when is_function(trigger_fun, 1) and is_function(callback_fun, 2) and is_list(opts) do
    timeout_ms = popup_timeout_ms(opts)
    main_tab_id = session.tab_id
    baseline_tabs = UserContextProcess.context_ids(session.user_context_pid)

    trigger_task = Task.async(fn -> run_popup_callback(trigger_fun, [session]) end)
    Process.unlink(trigger_task.pid)

    try do
      {popup_tab_id, trigger_outcome} =
        await_popup_tab!(session, baseline_tabs, trigger_task, timeout_ms)

      _ = await_popup_callback_result!(trigger_task, trigger_outcome, timeout_ms, "trigger callback")
      ensure_popup_tab_attached!(session, popup_tab_id)

      popup_session = %{
        session
        | tab_id: popup_tab_id,
          scope: nil,
          current_path: nil
      }

      run_popup_callback!(callback_fun, [session, popup_session], "callback")

      restore_main_tab!(session, main_tab_id, "with_popup/4")

      Browser.refresh_path(session)
    rescue
      error ->
        _ = restore_main_tab_safe(session, main_tab_id)
        reraise error, __STACKTRACE__
    catch
      kind, reason ->
        _ = restore_main_tab_safe(session, main_tab_id)
        :erlang.raise(kind, reason, __STACKTRACE__)
    after
      _ = Task.shutdown(trigger_task, :brutal_kill)
    end
  end

  @spec assert_download(Browser.t(), String.t(), Options.assert_download_opts()) :: Browser.t()
  def assert_download(%Browser{} = session, filename, opts \\ []) when is_binary(filename) and is_list(opts) do
    filename = non_empty_text!(filename, "assert_download/3 filename")
    timeout_ms = download_timeout_ms(opts)
    _download = await_download_match!(session, filename, timeout_ms)
    session
  end

  @spec evaluate_js(Browser.t(), String.t()) :: term()
  def evaluate_js(%Browser{} = session, expression) when is_binary(expression) do
    timeout_ms = @default_evaluate_timeout_ms

    result =
      Profiling.measure({:driver_operation, :browser, :evaluate_js}, fn ->
        evaluate_with_transient_retry(session, expression, timeout_ms)
      end)

    case result do
      {:ok, %{"result" => result}} ->
        decode_remote_value(result)

      {:ok, %{"type" => "exception", "exceptionDetails" => details} = payload} ->
        raise ArgumentError, "browser evaluate_js failed: #{exception_details_message(details, payload)}"

      {:ok, payload} ->
        raise ArgumentError, "unexpected browser evaluate result: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser evaluate_js failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec cookies(Browser.t()) :: [Types.cookie()]
  def cookies(%Browser{} = session) do
    params = %{"partition" => %{"type" => "context", "context" => session.tab_id}}

    case BiDi.command("storage.getCookies", params, bidi_opts(session)) do
      {:ok, %{"cookies" => cookies}} when is_list(cookies) ->
        Enum.map(cookies, &normalize_cookie/1)

      {:ok, payload} ->
        raise ArgumentError, "unexpected storage.getCookies result: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser cookies failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec cookie(Browser.t(), String.t()) :: Types.cookie() | nil
  def cookie(%Browser{} = session, name) when is_binary(name) do
    Enum.find(cookies(session), fn cookie -> cookie.name == name end)
  end

  @spec session_cookie(Browser.t()) :: Types.cookie() | nil
  def session_cookie(%Browser{} = session) do
    cookies = cookies(session)

    Enum.find(cookies, &(&1.http_only and &1.session)) ||
      Enum.find(cookies, & &1.session)
  end

  @spec add_cookies(Browser.t(), [Options.browser_cookie_arg()]) :: Browser.t()
  def add_cookies(%Browser{} = session, cookies) when is_list(cookies) do
    Enum.each(cookies, fn cookie_args ->
      cookie =
        cookie_args
        |> build_remote_cookie(session, "add_cookies/2")
        |> put_expiry(cookie_args)

      set_cookie(session, cookie, "add_cookies")
    end)

    session
  end

  @spec add_cookie(Browser.t(), String.t(), String.t(), Options.browser_add_cookie_opts()) ::
          Browser.t()
  def add_cookie(%Browser{} = session, name, value, opts \\ [])
      when is_binary(name) and is_binary(value) and is_list(opts) do
    cookie =
      [name: name, value: value]
      |> Keyword.merge(opts)
      |> build_remote_cookie(session, "add_cookie/4")

    set_cookie(session, cookie, "add_cookie")
  end

  @spec clear_cookies(Browser.t()) :: Browser.t()
  def clear_cookies(%Browser{} = session) do
    params = %{"partition" => %{"type" => "context", "context" => session.tab_id}}

    case BiDi.command("storage.deleteCookies", params, bidi_opts(session)) do
      {:ok, _} ->
        session

      {:error, reason, details} ->
        raise ArgumentError, "browser clear_cookies failed: #{reason} (#{inspect(details)})"
    end
  end

  defp evaluate_json(session, expression, timeout_ms) do
    with {:ok, result} <-
           Profiling.measure({:driver_operation, :browser, :evaluate_json}, fn ->
             evaluate_with_transient_retry(session, expression, max(timeout_ms, 1))
           end),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  defp extension_timeout_ms(%Browser{} = session, opts) when is_list(opts) do
    case Keyword.get(opts, :timeout) do
      timeout when is_integer(timeout) and timeout > 0 -> timeout
      _ -> max(session.timeout_ms, @default_evaluate_timeout_ms)
    end
  end

  defp evaluate_with_transient_retry(%Browser{} = session, expression, timeout_ms)
       when is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    started_at_ms = System.monotonic_time(:millisecond)
    do_evaluate_with_transient_retry(session, expression, timeout_ms, started_at_ms)
  end

  defp do_evaluate_with_transient_retry(session, expression, timeout_ms, started_at_ms) do
    remaining_timeout_ms = max(timeout_ms - elapsed_ms(started_at_ms), 1)
    tab_id = recovered_tab_id(session)

    case UserContextProcess.evaluate_with_timeout(
           session.user_context_pid,
           expression,
           remaining_timeout_ms,
           tab_id
         ) do
      {:error, reason, details} = error ->
        if navigation_transition_error?(reason, details) and remaining_timeout_ms > @transient_eval_retry_interval_ms do
          Process.sleep(@transient_eval_retry_interval_ms)
          do_evaluate_with_transient_retry(session, expression, timeout_ms, started_at_ms)
        else
          error
        end

      result ->
        result
    end
  end

  defp recovered_tab_id(%Browser{} = session) do
    case UserContextProcess.recover_active_tab(session.user_context_pid, session.tab_id) do
      {:ok, tab_id} when is_binary(tab_id) -> tab_id
      _ -> session.tab_id
    end
  end

  defp elapsed_ms(started_at_ms), do: System.monotonic_time(:millisecond) - started_at_ms

  defp navigation_transition_error?(reason, details) when is_binary(reason) and is_map(details) do
    message = details["message"] || details[:message] || ""
    payload = "#{reason}: #{message}"
    Enum.any?(@transient_navigation_eval_markers, &String.contains?(payload, &1))
  end

  defp navigation_transition_error?(_reason, _details), do: false

  defp decode_remote_json(%{"result" => %{"type" => "string", "value" => payload}}) when is_binary(payload) do
    case JSON.decode(payload) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "invalid json payload from browser: #{inspect(reason)}"}
    end
  end

  defp decode_remote_json(result) do
    {:error, "unexpected script.evaluate result: #{inspect(result)}"}
  end

  defp decode_remote_value(%{"type" => "null"}), do: nil
  defp decode_remote_value(%{"type" => "undefined"}), do: :undefined

  defp decode_remote_value(%{"type" => type, "value" => value}) when type in ["string", "number", "boolean", "bigint"] do
    value
  end

  defp decode_remote_value(%{"type" => "array", "value" => values}) when is_list(values) do
    Enum.map(values, &decode_remote_value/1)
  end

  defp decode_remote_value(%{"type" => "object", "value" => entries}) when is_list(entries) do
    Enum.reduce(entries, %{}, fn
      [key, value], acc when is_binary(key) ->
        Map.put(acc, key, decode_remote_value(value))

      _entry, acc ->
        acc
    end)
  end

  defp decode_remote_value(%{"type" => _type} = value), do: value
  defp decode_remote_value(value), do: value

  defp exception_details_message(%{"text" => text}, _payload) when is_binary(text) and text != "" do
    text
  end

  defp exception_details_message(_details, payload), do: inspect(payload)

  @spec normalize_cookie(Types.payload()) :: Types.cookie()
  defp normalize_cookie(cookie) when is_map(cookie) do
    session_cookie? =
      cookie["goog:session"] ||
        cookie["session"] ||
        is_nil(cookie["expiry"]) ||
        is_nil(cookie["expires"])

    %{
      name: cookie["name"],
      value: decode_remote_value(cookie["value"]),
      domain: cookie["domain"],
      path: cookie["path"],
      http_only: cookie["httpOnly"] || false,
      secure: cookie["secure"] || false,
      same_site: cookie["sameSite"],
      session: !!session_cookie?
    }
  end

  defp selector_opt!(opts) do
    case Keyword.get(opts, :selector) do
      nil -> nil
      selector when is_binary(selector) -> non_empty_selector!(selector, ":selector")
      other -> raise ArgumentError, ":selector must be a string, got: #{inspect(other)}"
    end
  end

  defp non_empty_selector!(value, label) when is_binary(value) do
    if String.trim(value) == "" do
      raise ArgumentError, "#{label} must be a non-empty CSS selector"
    else
      value
    end
  end

  defp non_empty_text!(value, label) when is_binary(value) do
    if String.trim(value) == "" do
      raise ArgumentError, "#{label} must be a non-empty string"
    else
      value
    end
  end

  @doc false
  @spec dialog_timeout_ms(Options.browser_assert_dialog_opts()) :: pos_integer()
  def dialog_timeout_ms(opts) when is_list(opts) do
    case Keyword.fetch(opts, :timeout) do
      {:ok, timeout} when is_integer(timeout) and timeout > 0 ->
        timeout

      {:ok, timeout} ->
        raise ArgumentError, "assert_dialog/3 :timeout must be a positive integer, got: #{inspect(timeout)}"

      :error ->
        opts
        |> merged_browser_opts()
        |> Keyword.get(:dialog_timeout_ms)
        |> normalize_positive_integer(@default_dialog_timeout_ms)
    end
  end

  @doc false
  @spec popup_timeout_ms(Options.browser_with_popup_opts()) :: pos_integer()
  def popup_timeout_ms(opts) when is_list(opts) do
    case Keyword.get(opts, :timeout, @default_popup_timeout_ms) do
      timeout when is_integer(timeout) and timeout > 0 ->
        timeout

      timeout ->
        raise ArgumentError, "with_popup/4 :timeout must be a positive integer, got: #{inspect(timeout)}"
    end
  end

  @doc false
  @spec download_timeout_ms(Options.assert_download_opts()) :: pos_integer()
  def download_timeout_ms(opts) when is_list(opts) do
    case Keyword.get(opts, :timeout, @default_download_timeout_ms) do
      timeout when is_integer(timeout) and timeout > 0 ->
        timeout

      timeout ->
        raise ArgumentError, "assert_download/3 :timeout must be a positive integer, got: #{inspect(timeout)}"
    end
  end

  defp merged_browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp await_open_dialog!(session, locator, timeout_ms) do
    case UserContextProcess.await_dialog_open(session.user_context_pid, timeout_ms, session.tab_id) do
      {:ok, %{} = dialog} ->
        dialog

      {:error, :timeout, events} ->
        handle_dialog_timeout!(locator, events)

      {:error, reason, details} ->
        raise AssertionError,
          message: "assert_dialog/3 failed while waiting for dialog: #{reason} (#{inspect(details)})"
    end
  end

  defp handle_dialog_timeout!(locator, events) do
    case matching_observed_dialog(events, locator) do
      {:ok, %{} = dialog} ->
        dialog

      :error ->
        case latest_observed_dialog(events) do
          {:ok, %{} = dialog} ->
            observed_message = Map.get(dialog, "message", "")

            raise AssertionError,
              message:
                "assert_dialog/3 expected #{expected_dialog_text(locator)} but observed #{inspect(observed_message)}"

          :error ->
            raise_dialog_timeout!(locator, events)
        end
    end
  end

  defp matching_observed_dialog(events, locator) when is_list(events) do
    events
    |> Enum.filter(&match?(%{"method" => "browsingContext.userPromptOpened"}, &1))
    |> Enum.reverse()
    |> Enum.find(&dialog_matches_locator?(&1, locator))
    |> case do
      %{} = dialog -> {:ok, dialog}
      _ -> :error
    end
  end

  defp matching_observed_dialog(_events, _locator), do: :error

  defp latest_observed_dialog(events) when is_list(events) do
    events
    |> Enum.filter(&match?(%{"method" => "browsingContext.userPromptOpened"}, &1))
    |> List.last()
    |> case do
      %{} = dialog -> {:ok, dialog}
      _ -> :error
    end
  end

  defp latest_observed_dialog(_events), do: :error

  defp dialog_matches_locator?(dialog, %Locator{value: expected, opts: locator_opts}) when is_map(dialog) do
    actual = dialog["message"] || ""
    match_opts = Keyword.take(locator_opts, [:exact, :normalize_ws])
    Query.match_text?(actual, expected, match_opts)
  end

  defp raise_dialog_timeout!(locator, events) when is_list(events) do
    observed_messages =
      events
      |> Enum.filter(&match?(%{"method" => "browsingContext.userPromptOpened"}, &1))
      |> Enum.map(&Map.get(&1, "message"))
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    raise AssertionError,
      message:
        "assert_dialog/3 timed out waiting for #{expected_dialog_text(locator)}; observed dialogs: #{inspect(observed_messages)}"
  end

  defp raise_dialog_timeout!(locator, _events) do
    raise AssertionError,
      message: "assert_dialog/3 timed out waiting for #{expected_dialog_text(locator)}; observed dialogs: []"
  end

  defp assert_dialog_text_match!(%Locator{value: expected, opts: locator_opts} = locator, %{} = dialog) do
    actual = dialog["message"] || ""
    match_opts = Keyword.take(locator_opts, [:exact, :normalize_ws])

    if Query.match_text?(actual, expected, match_opts) do
      :ok
    else
      raise AssertionError,
        message: "assert_dialog/3 expected #{expected_dialog_text(locator)} but observed #{inspect(actual)}"
    end
  end

  defp expected_dialog_text(%Locator{value: %Regex{} = expected}) do
    "dialog text matching #{inspect(expected)}"
  end

  defp expected_dialog_text(%Locator{value: expected, opts: opts}) when is_binary(expected) do
    if Keyword.get(opts, :exact, false) do
      "dialog text #{inspect(expected)}"
    else
      "dialog text containing #{inspect(expected)}"
    end
  end

  defp ensure_dialog_auto_accepted!(session, timeout_ms, dialog) do
    params = dialog_prompt_params(session.tab_id, dialog["type"])
    opts = Keyword.put(bidi_opts(session), :timeout, timeout_ms)

    case BiDi.command("browsingContext.handleUserPrompt", params, opts) do
      {:ok, _payload} ->
        :ok

      {:error, _reason, %{"error" => "no such alert"}} ->
        :ok

      {:error, reason, details} ->
        raise ArgumentError,
              "assert_dialog/3 failed to auto-accept observed dialog: #{reason} (#{inspect(details)})"
    end
  end

  defp poll_action_task(_action_task, {:ok, _} = action_outcome), do: action_outcome
  defp poll_action_task(action_task, :pending), do: Task.yield(action_task, 0) || :pending

  defp await_popup_tab!(session, baseline_tabs, trigger_task, timeout_ms) do
    popup_task =
      Task.async(fn -> UserContextProcess.await_popup_tab(session.user_context_pid, baseline_tabs, timeout_ms) end)

    Process.unlink(popup_task.pid)
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    try do
      await_popup_tab_loop(trigger_task, popup_task, session, baseline_tabs, deadline, :pending)
    after
      _ = Task.shutdown(popup_task, :brutal_kill)
    end
  end

  defp await_popup_tab_loop(trigger_task, popup_task, session, baseline_tabs, deadline, trigger_outcome) do
    trigger_outcome = poll_action_task(trigger_task, trigger_outcome)
    raise_if_trigger_failed_before_popup!(trigger_outcome)

    case handle_popup_task_result(Task.yield(popup_task, 0), session, baseline_tabs, deadline, trigger_outcome) do
      {:ok, popup_tab_id, trigger_outcome} ->
        {popup_tab_id, trigger_outcome}

      {:recurse, trigger_outcome} ->
        await_popup_tab_loop(trigger_task, popup_task, session, baseline_tabs, deadline, trigger_outcome)
    end
  end

  defp raise_if_trigger_failed_before_popup!({:ok, {:action_failure, formatted_error}}) do
    raise AssertionError, message: "with_popup/4 trigger callback failed before popup capture: #{formatted_error}"
  end

  defp raise_if_trigger_failed_before_popup!(_trigger_outcome), do: :ok

  defp handle_popup_task_result({:ok, {:ok, popup_tab_id}}, _session, _baseline_tabs, _deadline, trigger_outcome) do
    {:ok, popup_tab_id, trigger_outcome}
  end

  defp handle_popup_task_result({:ok, {:error, :timeout}}, _session, _baseline_tabs, _deadline, _trigger_outcome) do
    raise AssertionError, message: "with_popup/4 timed out waiting for popup tab"
  end

  defp handle_popup_task_result({:ok, {:error, :multiple, tabs}}, _session, _baseline_tabs, _deadline, _trigger_outcome) do
    raise AssertionError,
      message: "with_popup/4 observed multiple new tabs while capturing popup: #{inspect(tabs)}"
  end

  defp handle_popup_task_result({:ok, {:error, reason, details}}, _session, _baseline_tabs, _deadline, _trigger_outcome) do
    raise AssertionError,
      message: "with_popup/4 failed while waiting for popup tab: #{reason} (#{inspect(details)})"
  end

  defp handle_popup_task_result({:exit, reason}, _session, _baseline_tabs, _deadline, _trigger_outcome) do
    raise AssertionError,
      message: "with_popup/4 failed while waiting for popup tab: #{Exception.format_exit(reason)}"
  end

  defp handle_popup_task_result(nil, session, baseline_tabs, deadline, trigger_outcome) do
    case popup_poll_wait_ms(deadline) do
      0 ->
        popup_task_deadline_probe!(session, baseline_tabs, trigger_outcome)

      wait_ms ->
        Process.sleep(wait_ms)
        {:recurse, trigger_outcome}
    end
  end

  defp popup_task_deadline_probe!(session, baseline_tabs, trigger_outcome) do
    case UserContextProcess.await_popup_tab(session.user_context_pid, baseline_tabs, 1) do
      {:ok, popup_tab_id} ->
        {:ok, popup_tab_id, trigger_outcome}

      {:error, :multiple, tabs} ->
        raise AssertionError,
          message: "with_popup/4 observed multiple new tabs while capturing popup: #{inspect(tabs)}"

      {:error, :timeout} ->
        raise AssertionError, message: "with_popup/4 timed out waiting for popup tab"
    end
  end

  defp popup_poll_wait_ms(deadline) do
    now = System.monotonic_time(:millisecond)
    remaining = max(deadline - now, 0)
    min(remaining, @popup_task_poll_ms)
  end

  defp ensure_popup_tab_attached!(session, popup_tab_id) do
    case UserContextProcess.attach_tab(session.user_context_pid, popup_tab_id) do
      :ok ->
        :ok

      {:error, reason, details} ->
        raise AssertionError,
          message: "with_popup/4 failed to attach popup tab #{inspect(popup_tab_id)}: #{reason} (#{inspect(details)})"
    end
  end

  defp await_popup_callback_result!(_task, {:ok, action_outcome}, _timeout_ms, _label) do
    unwrap_popup_callback_outcome!(action_outcome, "trigger callback")
  end

  defp await_popup_callback_result!(task, :pending, timeout_ms, label) do
    wait_ms = timeout_ms + 1_000

    case Task.yield(task, wait_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, action_outcome} ->
        unwrap_popup_callback_outcome!(action_outcome, label)

      {:exit, reason} ->
        raise AssertionError, message: "with_popup/4 #{label} failed: #{Exception.format_exit(reason)}"

      nil ->
        raise AssertionError, message: "with_popup/4 timed out waiting for #{label} completion"
    end
  end

  defp run_popup_callback(fun, args) when is_function(fun) and is_list(args) do
    {:action_result, apply(fun, args)}
  rescue
    error ->
      {:action_failure, Exception.format(:error, error, __STACKTRACE__)}
  catch
    kind, reason ->
      {:action_failure, Exception.format(kind, reason, __STACKTRACE__)}
  end

  defp run_popup_callback!(fun, args, label) when is_function(fun) and is_list(args) do
    case run_popup_callback(fun, args) do
      {:action_result, _result} ->
        :ok

      {:action_failure, formatted_error} ->
        raise AssertionError, message: "with_popup/4 #{label} failed: #{formatted_error}"
    end
  end

  defp unwrap_popup_callback_outcome!({:action_result, _result}, _label), do: :ok

  defp unwrap_popup_callback_outcome!({:action_failure, formatted_error}, label) do
    raise AssertionError, message: "with_popup/4 #{label} failed: #{formatted_error}"
  end

  defp restore_main_tab!(session, main_tab_id, operation_name) do
    case UserContextProcess.switch_tab(session.user_context_pid, main_tab_id) do
      :ok ->
        :ok

      {:error, reason, details} ->
        raise ArgumentError,
              "#{operation_name} failed to restore main tab: #{reason} (#{inspect(details)})"
    end
  end

  defp restore_main_tab_safe(session, main_tab_id) do
    _ = UserContextProcess.switch_tab(session.user_context_pid, main_tab_id)
    :ok
  end

  defp host_from_base_url(base_url) when is_binary(base_url) do
    case URI.parse(base_url) do
      %URI{host: host} when is_binary(host) and host != "" -> host
      _ -> raise ArgumentError, "could not infer cookie domain from base URL: #{inspect(base_url)}"
    end
  end

  defp build_remote_cookie(cookie_args, %Browser{} = session, op_name) when is_list(cookie_args) do
    name = non_empty_text!(Keyword.fetch!(cookie_args, :name), "#{op_name} cookie :name")
    value = non_empty_text!(Keyword.fetch!(cookie_args, :value), "#{op_name} cookie :value")
    url = Keyword.get(cookie_args, :url)
    domain = Keyword.get(cookie_args, :domain) || cookie_domain_from_url(url) || host_from_base_url(session.base_url)
    path = Keyword.get(cookie_args, :path) || cookie_path_from_url(url) || "/"
    http_only = Keyword.get(cookie_args, :http_only, false)
    secure = Keyword.get(cookie_args, :secure, false)
    same_site = normalize_same_site(Keyword.get(cookie_args, :same_site, :lax))

    %{
      "name" => name,
      "value" => %{"type" => "string", "value" => value},
      "domain" => domain,
      "path" => path,
      "httpOnly" => http_only,
      "secure" => secure,
      "sameSite" => same_site
    }
  end

  defp put_expiry(cookie, cookie_args) when is_map(cookie) and is_list(cookie_args) do
    case Keyword.get(cookie_args, :expires) do
      nil -> cookie
      expires -> Map.put(cookie, "expiry", expires)
    end
  end

  defp set_cookie(%Browser{} = session, cookie, op_name) when is_map(cookie) do
    params = %{
      "cookie" => cookie,
      "partition" => %{"type" => "context", "context" => session.tab_id}
    }

    case BiDi.command("storage.setCookie", params, bidi_opts(session)) do
      {:ok, _} ->
        session

      {:error, reason, details} ->
        raise ArgumentError, "browser #{op_name} failed: #{reason} (#{inspect(details)})"
    end
  end

  defp cookie_domain_from_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) and host != "" -> host
      _ -> raise ArgumentError, "could not infer cookie domain from url: #{inspect(url)}"
    end
  end

  defp cookie_domain_from_url(nil), do: nil

  defp cookie_path_from_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{path: path} when is_binary(path) and path != "" -> path
      %URI{} -> "/"
    end
  end

  defp cookie_path_from_url(nil), do: nil

  defp normalize_same_site(value) when is_atom(value) or is_binary(value) do
    normalized =
      value
      |> to_string()
      |> String.downcase()

    if normalized in ["lax", "strict", "none"] do
      normalized
    else
      raise ArgumentError,
            "add_cookie/4 :same_site must be :lax, :strict, :none (or equivalent strings), got: #{inspect(value)}"
    end
  end

  defp normalize_same_site(value) do
    raise ArgumentError,
          "add_cookie/4 :same_site must be :lax, :strict, :none (or equivalent strings), got: #{inspect(value)}"
  end

  defp dialog_prompt_params(context_id, "prompt"), do: %{"context" => context_id, "accept" => true, "userText" => ""}
  defp dialog_prompt_params(context_id, _type), do: %{"context" => context_id, "accept" => true}

  defp await_download_match!(session, expected_filename, timeout_ms) do
    case UserContextProcess.await_download(session.user_context_pid, expected_filename, timeout_ms, session.tab_id) do
      {:ok, event} when is_map(event) ->
        event

      {:error, :timeout, events} ->
        raise_download_timeout!(expected_filename, events)

      {:error, reason, details} ->
        raise AssertionError,
          message: "assert_download/3 failed while waiting for download: #{reason} (#{inspect(details)})"
    end
  end

  defp raise_download_timeout!(expected_filename, events) when is_binary(expected_filename) and is_list(events) do
    observed_filenames =
      events
      |> Enum.map(&Map.get(&1, "suggestedFilename"))
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    raise AssertionError,
      message:
        "assert_download/3 timed out waiting for #{inspect(expected_filename)}; observed downloads: #{inspect(observed_filenames)}"
  end

  defp bidi_opts(%Browser{bidi_opts: bidi_opts, browser_name: browser_name}) when is_list(bidi_opts) do
    Keyword.put_new(bidi_opts, :browser_name, browser_name)
  end

  defp bidi_opts(%Browser{browser_name: browser_name}), do: [browser_name: browser_name]

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp prepare_type_expression(selector, clear?) do
    encoded_selector = JSON.encode!(selector)
    encoded_clear = JSON.encode!(clear?)

    """
    (() => {
      const selector = #{encoded_selector};
      const clear = #{encoded_clear};
      const target = selector ? document.querySelector(selector) : document.activeElement;

      if (!target) {
        return JSON.stringify({ ok: false, reason: "target_not_found", selector });
      }

      if (!("value" in target) && !target.isContentEditable) {
        return JSON.stringify({ ok: false, reason: "target_not_typable", selector });
      }

      if (typeof target.focus === "function") {
        target.focus();
      }

      if (document.activeElement !== target) {
        return JSON.stringify({ ok: false, reason: "target_not_focusable", selector });
      }

      if (!clear) {
        return JSON.stringify({ ok: true, selector });
      }

      if ("value" in target) {
        target.value = "";

        if (typeof target.setSelectionRange === "function") {
          target.setSelectionRange(0, 0);
        }

        return JSON.stringify({ ok: true, selector });
      }

      if (target.isContentEditable) {
        target.textContent = "";
        const selection = window.getSelection();

        if (selection) {
          const range = document.createRange();
          range.selectNodeContents(target);
          range.collapse(true);
          selection.removeAllRanges();
          selection.addRange(range);
        }

        return JSON.stringify({ ok: true, selector });
      }

      return JSON.stringify({ ok: false, reason: "target_not_typable", selector });
    })()
    """
  end

  defp focus_expression(selector) do
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const selector = #{encoded_selector};
      const target = selector ? document.querySelector(selector) : document.activeElement;

      if (!target) {
        return JSON.stringify({ ok: false, reason: "target_not_found", selector });
      }

      if (typeof target.focus === "function") {
        target.focus();
      }

      if (document.activeElement !== target) {
        return JSON.stringify({ ok: false, reason: "target_not_focusable", selector });
      }

      return JSON.stringify({ ok: true, selector });
    })()
    """
  end

  defp perform_keyboard_actions(_session, [], _timeout_ms), do: :ok

  defp perform_keyboard_actions(%Browser{} = session, actions, timeout_ms)
       when is_list(actions) and is_integer(timeout_ms) do
    params = %{
      "context" => session.tab_id,
      "actions" => [
        %{
          "id" => "cerberus-keyboard",
          "type" => "key",
          "actions" => actions
        }
      ]
    }

    case BiDi.command("input.performActions", params, Keyword.put(bidi_opts(session), :timeout, max(timeout_ms, 1))) do
      {:ok, _payload} ->
        :ok

      {:error, reason, details} ->
        {:error, reason, details}
    end
  end

  defp type_actions(text) when is_binary(text) do
    text
    |> String.codepoints()
    |> Enum.flat_map(&press_actions/1)
  end

  defp press_actions(key) when is_binary(key) do
    tokens = split_key_tokens(key)

    case tokens do
      [] ->
        raise ArgumentError, "browser press failed: empty key chord"

      [token] ->
        [key_action("keyDown", token), key_action("keyUp", token)]

      _tokens ->
        {modifier_tokens, [key_token]} = Enum.split(tokens, length(tokens) - 1)

        if Enum.any?(modifier_tokens, &(not modifier_key_token?(&1))) do
          raise ArgumentError,
                "browser press failed: only modifier keys may appear before the final chord key: #{inspect(key)}"
        end

        Enum.map(modifier_tokens, &key_action("keyDown", &1)) ++
          [key_action("keyDown", key_token), key_action("keyUp", key_token)] ++
          Enum.reverse(Enum.map(modifier_tokens, &key_action("keyUp", &1)))
    end
  end

  defp split_key_tokens(key_string) when is_binary(key_string) do
    {parts, current} =
      key_string
      |> String.graphemes()
      |> Enum.reduce({[], ""}, fn
        "+", {parts, current} when current != "" -> {[current | parts], ""}
        char, {parts, current} -> {parts, current <> char}
      end)

    parts =
      case current do
        "" -> parts
        value -> [value | parts]
      end

    parts
    |> Enum.reverse()
    |> Enum.map(&normalize_key_token/1)
  end

  defp normalize_key_token(""), do: ""

  defp normalize_key_token("ControlOrMeta") do
    case :os.type() do
      {:unix, :darwin} -> "Meta"
      _ -> "Control"
    end
  end

  defp normalize_key_token(token), do: token

  defp modifier_key_token?(token) when is_binary(token) do
    MapSet.member?(@modifier_key_tokens, token)
  end

  defp key_action(action_type, token) when action_type in ["keyDown", "keyUp"] and is_binary(token) do
    %{"type" => action_type, "value" => webdriver_key_value!(token)}
  end

  defp webdriver_key_value!(token) when is_binary(token) do
    case resolve_webdriver_key_value(token) do
      nil -> raise ArgumentError, "browser press failed: unknown key #{inspect(token)}"
      value -> value
    end
  end

  defp resolve_webdriver_key_value(""), do: raise(ArgumentError, "browser press failed: empty key token")
  defp resolve_webdriver_key_value("\n"), do: Map.fetch!(@webdriver_key_values, "Enter")
  defp resolve_webdriver_key_value("\r"), do: Map.fetch!(@webdriver_key_values, "Enter")
  defp resolve_webdriver_key_value("\t"), do: Map.fetch!(@webdriver_key_values, "Tab")

  defp resolve_webdriver_key_value(token) when is_binary(token) do
    cond do
      String.length(token) == 1 ->
        token

      value = Map.get(@webdriver_key_values, token) ->
        value

      Regex.match?(~r/^Key[A-Z]$/, token) ->
        token |> String.replace_prefix("Key", "") |> String.downcase()

      Regex.match?(~r/^Digit[0-9]$/, token) ->
        String.replace_prefix(token, "Digit", "")

      true ->
        nil
    end
  end

  defp drag_expression(source_selector, target_selector) do
    encoded_source_selector = JSON.encode!(source_selector)
    encoded_target_selector = JSON.encode!(target_selector)

    """
    (() => {
      const sourceSelector = #{encoded_source_selector};
      const targetSelector = #{encoded_target_selector};
      const source = document.querySelector(sourceSelector);
      const target = document.querySelector(targetSelector);

      if (!source || !target) {
        return JSON.stringify({
          ok: false,
          reason: "missing_source_or_target",
          sourceSelector,
          targetSelector
        });
      }

      const dataTransfer = new DataTransfer();

      source.dispatchEvent(new DragEvent("dragstart", { bubbles: true, cancelable: true, dataTransfer }));
      target.dispatchEvent(new DragEvent("dragenter", { bubbles: true, cancelable: true, dataTransfer }));
      target.dispatchEvent(new DragEvent("dragover", { bubbles: true, cancelable: true, dataTransfer }));
      target.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer }));
      source.dispatchEvent(new DragEvent("dragend", { bubbles: true, cancelable: true, dataTransfer }));

      return JSON.stringify({ ok: true, sourceSelector, targetSelector });
    })()
    """
  end
end
