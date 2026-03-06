defmodule Cerberus.Driver.Browser.Extensions do
  @moduledoc false

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Evaluate
  alias Cerberus.Driver.Browser.Types
  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Query
  alias ExUnit.AssertionError

  @default_dialog_timeout_ms 1_500
  @default_popup_timeout_ms 1_500
  @default_download_timeout_ms 1_500
  @default_evaluate_timeout_ms 10_000
  @popup_task_poll_ms 10

  @spec type(BrowserSession.t(), String.t(), Options.browser_type_opts()) :: BrowserSession.t()
  def type(%BrowserSession{} = session, text, opts \\ []) when is_binary(text) and is_list(opts) do
    selector = selector_opt!(opts)
    clear? = Keyword.get(opts, :clear, false)
    timeout_ms = extension_timeout_ms(session, opts)

    case evaluate_json(session, type_expression(selector, text, clear?), timeout_ms) do
      {:ok, %{"ok" => true}} ->
        session

      {:ok, payload} ->
        raise ArgumentError, "browser type failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser type failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec press(BrowserSession.t(), String.t(), Options.browser_press_opts()) :: BrowserSession.t()
  def press(%BrowserSession{} = session, key, opts \\ []) when is_binary(key) and is_list(opts) do
    selector = selector_opt!(opts)
    timeout_ms = extension_timeout_ms(session, opts)

    case evaluate_json(session, press_expression(selector, key), timeout_ms) do
      {:ok, %{"ok" => true}} ->
        session

      {:ok, payload} ->
        raise ArgumentError, "browser press failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser press failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec drag(BrowserSession.t(), String.t(), String.t(), Options.browser_drag_opts()) :: BrowserSession.t()
  def drag(%BrowserSession{} = session, source_selector, target_selector, opts \\ [])
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

  @spec assert_dialog(BrowserSession.t(), Locator.t(), Options.browser_assert_dialog_opts()) :: BrowserSession.t()
  def assert_dialog(%BrowserSession{} = session, %Locator{} = locator, opts \\ []) when is_list(opts) do
    timeout_ms = dialog_timeout_ms(opts)
    dialog = await_open_dialog!(session, locator, timeout_ms)
    assert_dialog_text_match!(locator, dialog)
    ensure_dialog_auto_accepted!(session, timeout_ms, dialog)
    session
  end

  @spec with_popup(
          BrowserSession.t(),
          (BrowserSession.t() -> term()),
          (BrowserSession.t(), BrowserSession.t() -> term()),
          Options.browser_with_popup_opts()
        ) :: BrowserSession.t()
  def with_popup(%BrowserSession{} = session, trigger_fun, callback_fun, opts \\ [])
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

      BrowserSession.refresh_path(session)
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

  @spec assert_download(BrowserSession.t(), String.t(), Options.assert_download_opts()) :: BrowserSession.t()
  def assert_download(%BrowserSession{} = session, filename, opts \\ []) when is_binary(filename) and is_list(opts) do
    filename = non_empty_text!(filename, "assert_download/3 filename")
    timeout_ms = download_timeout_ms(opts)
    _download = await_download_match!(session, filename, timeout_ms)
    session
  end

  @spec evaluate_js(BrowserSession.t(), String.t()) :: term()
  def evaluate_js(%BrowserSession{} = session, expression) when is_binary(expression) do
    timeout_ms = @default_evaluate_timeout_ms

    case Evaluate.with_dialog_unblock(
           session.user_context_pid,
           session.tab_id,
           expression,
           timeout_ms,
           bidi_opts(session)
         ) do
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

  @spec cookies(BrowserSession.t()) :: [Types.cookie()]
  def cookies(%BrowserSession{} = session) do
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

  @spec cookie(BrowserSession.t(), String.t()) :: Types.cookie() | nil
  def cookie(%BrowserSession{} = session, name) when is_binary(name) do
    Enum.find(cookies(session), fn cookie -> cookie.name == name end)
  end

  @spec session_cookie(BrowserSession.t()) :: Types.cookie() | nil
  def session_cookie(%BrowserSession{} = session) do
    cookies = cookies(session)

    Enum.find(cookies, &(&1.http_only and &1.session)) ||
      Enum.find(cookies, & &1.session)
  end

  @spec add_cookies(BrowserSession.t(), [Options.browser_cookie_arg()]) :: BrowserSession.t()
  def add_cookies(%BrowserSession{} = session, cookies) when is_list(cookies) do
    Enum.each(cookies, fn cookie_args ->
      cookie =
        cookie_args
        |> build_remote_cookie(session, "add_cookies/2")
        |> put_expiry(cookie_args)

      set_cookie(session, cookie, "add_cookies")
    end)

    session
  end

  @spec add_cookie(BrowserSession.t(), String.t(), String.t(), Options.browser_add_cookie_opts()) ::
          BrowserSession.t()
  def add_cookie(%BrowserSession{} = session, name, value, opts \\ [])
      when is_binary(name) and is_binary(value) and is_list(opts) do
    cookie =
      [name: name, value: value]
      |> Keyword.merge(opts)
      |> build_remote_cookie(session, "add_cookie/4")

    set_cookie(session, cookie, "add_cookie")
  end

  @spec clear_cookies(BrowserSession.t()) :: BrowserSession.t()
  def clear_cookies(%BrowserSession{} = session) do
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
           Evaluate.with_dialog_unblock(
             session.user_context_pid,
             session.tab_id,
             expression,
             max(timeout_ms, 1),
             bidi_opts(session)
           ),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  defp extension_timeout_ms(%BrowserSession{} = session, opts) when is_list(opts) do
    case Keyword.get(opts, :timeout) do
      timeout when is_integer(timeout) and timeout > 0 -> timeout
      _ -> session.ready_timeout_ms
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

  defp build_remote_cookie(cookie_args, %BrowserSession{} = session, op_name) when is_list(cookie_args) do
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

  defp set_cookie(%BrowserSession{} = session, cookie, op_name) when is_map(cookie) do
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

  defp bidi_opts(%BrowserSession{bidi_opts: bidi_opts, browser_name: browser_name}) when is_list(bidi_opts) do
    Keyword.put_new(bidi_opts, :browser_name, browser_name)
  end

  defp bidi_opts(%BrowserSession{browser_name: browser_name}), do: [browser_name: browser_name]

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp type_expression(selector, text, clear?) do
    encoded_selector = JSON.encode!(selector)
    encoded_text = JSON.encode!(text)
    encoded_clear = JSON.encode!(clear?)

    """
    (() => {
      const selector = #{encoded_selector};
      const text = #{encoded_text};
      const clear = #{encoded_clear};
      const target = selector ? document.querySelector(selector) : document.activeElement;

      if (!target) {
        return JSON.stringify({ ok: false, reason: "target_not_found", selector });
      }

      if (typeof target.focus === "function") {
        target.focus();
      }

      if (clear && "value" in target) {
        target.value = "";
      }

      if ("value" in target) {
        const current = String(target.value || "");
        const start = Number.isInteger(target.selectionStart) ? target.selectionStart : current.length;
        const end = Number.isInteger(target.selectionEnd) ? target.selectionEnd : current.length;

        if (typeof target.setRangeText === "function") {
          target.setRangeText(text, start, end, "end");
        } else {
          target.value = current.slice(0, start) + text + current.slice(end);
        }
      } else if (target.isContentEditable) {
        const existing = clear ? "" : String(target.textContent || "");
        target.textContent = existing + text;
      } else {
        return JSON.stringify({ ok: false, reason: "target_not_typable", selector });
      }

      try {
        target.dispatchEvent(new InputEvent("input", { bubbles: true, data: text, inputType: "insertText" }));
      } catch (_error) {
        target.dispatchEvent(new Event("input", { bubbles: true }));
      }

      target.dispatchEvent(new Event("change", { bubbles: true }));

      const value = "value" in target ? String(target.value || "") : String(target.textContent || "");
      return JSON.stringify({ ok: true, selector, text, value });
    })()
    """
  end

  defp press_expression(selector, key) do
    encoded_selector = JSON.encode!(selector)
    encoded_key = JSON.encode!(key)

    """
    (() => {
      const selector = #{encoded_selector};
      const key = #{encoded_key};
      const target = selector ? document.querySelector(selector) : document.activeElement;

      if (!target) {
        return JSON.stringify({ ok: false, reason: "target_not_found", selector, key });
      }

      if (typeof target.focus === "function") {
        target.focus();
      }

      const keyboardEventInit = {
        key,
        bubbles: true,
        cancelable: true
      };

      target.dispatchEvent(new KeyboardEvent("keydown", keyboardEventInit));

      let submitted = false;

      if (key === "Enter" && target.form && typeof target.form.requestSubmit === "function") {
        target.form.requestSubmit();
        submitted = true;
      }

      target.dispatchEvent(new KeyboardEvent("keyup", keyboardEventInit));

      return JSON.stringify({ ok: true, selector, key, submitted });
    })()
    """
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
