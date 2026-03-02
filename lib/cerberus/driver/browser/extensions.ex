defmodule Cerberus.Driver.Browser.Extensions do
  @moduledoc false

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.UserContextProcess
  alias ExUnit.AssertionError

  @dialog_events [
    "browsingContext.userPromptOpened",
    "browsingContext.userPromptClosed"
  ]

  @default_dialog_timeout_ms 1_500
  @default_popup_timeout_ms 1_500
  @dialog_poll_ms 25
  @popup_poll_ms 25

  @spec type(BrowserSession.t(), String.t(), keyword()) :: BrowserSession.t()
  def type(%BrowserSession{} = session, text, opts \\ []) when is_binary(text) and is_list(opts) do
    selector = selector_opt!(opts)
    clear? = Keyword.get(opts, :clear, false)

    case evaluate_json(session, type_expression(selector, text, clear?)) do
      {:ok, %{"ok" => true}} ->
        session

      {:ok, payload} ->
        raise ArgumentError, "browser type failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser type failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec press(BrowserSession.t(), String.t(), keyword()) :: BrowserSession.t()
  def press(%BrowserSession{} = session, key, opts \\ []) when is_binary(key) and is_list(opts) do
    selector = selector_opt!(opts)

    case evaluate_json(session, press_expression(selector, key)) do
      {:ok, %{"ok" => true}} ->
        session

      {:ok, payload} ->
        raise ArgumentError, "browser press failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser press failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec drag(BrowserSession.t(), String.t(), String.t()) :: BrowserSession.t()
  def drag(%BrowserSession{} = session, source_selector, target_selector)
      when is_binary(source_selector) and is_binary(target_selector) do
    source_selector = non_empty_selector!(source_selector, "drag/3 source selector")
    target_selector = non_empty_selector!(target_selector, "drag/3 target selector")

    case evaluate_json(session, drag_expression(source_selector, target_selector)) do
      {:ok, %{"ok" => true}} ->
        session

      {:ok, payload} ->
        raise ArgumentError, "browser drag failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser drag failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec with_dialog(BrowserSession.t(), (BrowserSession.t() -> term()), keyword()) ::
          BrowserSession.t()
  def with_dialog(%BrowserSession{} = session, action, opts \\ []) when is_function(action, 1) and is_list(opts) do
    timeout_ms = dialog_timeout_ms(opts)
    expected_message = Keyword.get(opts, :message)
    main_tab_id = session.tab_id

    protocol_subscription_id = subscribe_dialog_protocol_events!(session)
    :ok = subscribe_dialog_events!(session)
    flush_stale_dialog_events(session.tab_id)
    action_task = Task.async(fn -> run_dialog_action(action, session) end)
    Process.unlink(action_task.pid)

    try do
      {opened, action_outcome} =
        await_dialog_opened_event!(session.tab_id, action_task, timeout_ms)

      handle_dialog_prompt!(session, timeout_ms)
      closed = await_dialog_event!("browsingContext.userPromptClosed", session.tab_id, timeout_ms)
      _ = await_dialog_action_result!(action_task, action_outcome, timeout_ms)

      observed = %{
        type: opened["type"],
        message: opened["message"],
        handler: opened["handler"],
        accepted: Map.get(closed, "accepted", false)
      }

      assert_dialog_message!(observed, expected_message)
      restore_main_tab!(session, main_tab_id, "with_dialog/3")

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
      _ = Task.shutdown(action_task, :brutal_kill)
      unsubscribe_dialog_events(session)
      unsubscribe_dialog_protocol_events(protocol_subscription_id, session)
    end
  end

  @spec with_popup(
          BrowserSession.t(),
          (BrowserSession.t() -> term()),
          (BrowserSession.t(), BrowserSession.t() -> term()),
          keyword()
        ) :: BrowserSession.t()
  def with_popup(%BrowserSession{} = session, trigger_fun, callback_fun, opts \\ [])
      when is_function(trigger_fun, 1) and is_function(callback_fun, 2) and is_list(opts) do
    timeout_ms = popup_timeout_ms(opts)
    main_tab_id = session.tab_id
    baseline_tabs = MapSet.new(UserContextProcess.tabs(session.user_context_pid))

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

  @spec evaluate_js(BrowserSession.t(), String.t()) :: term()
  def evaluate_js(%BrowserSession{} = session, expression) when is_binary(expression) do
    case UserContextProcess.evaluate(session.user_context_pid, expression, session.tab_id) do
      {:ok, %{"result" => result}} ->
        decode_remote_value(result)

      {:ok, payload} ->
        raise ArgumentError, "unexpected browser evaluate result: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser evaluate_js failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec cookies(BrowserSession.t()) :: [map()]
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

  @spec cookie(BrowserSession.t(), String.t()) :: map() | nil
  def cookie(%BrowserSession{} = session, name) when is_binary(name) do
    Enum.find(cookies(session), fn cookie -> cookie.name == name end)
  end

  @spec session_cookie(BrowserSession.t()) :: map() | nil
  def session_cookie(%BrowserSession{} = session) do
    cookies = cookies(session)

    Enum.find(cookies, &(&1.http_only and &1.session)) ||
      Enum.find(cookies, & &1.session)
  end

  @spec add_cookie(BrowserSession.t(), String.t(), String.t(), keyword()) :: BrowserSession.t()
  def add_cookie(%BrowserSession{} = session, name, value, opts \\ [])
      when is_binary(name) and is_binary(value) and is_list(opts) do
    name = non_empty_text!(name, "add_cookie/4 name")
    domain = Keyword.get(opts, :domain, host_from_base_url(session.base_url))
    path = Keyword.get(opts, :path, "/")
    http_only = Keyword.get(opts, :http_only, false)
    secure = Keyword.get(opts, :secure, false)
    same_site = normalize_same_site(Keyword.get(opts, :same_site, :lax))

    cookie = %{
      "name" => name,
      "value" => %{"type" => "string", "value" => value},
      "domain" => domain,
      "path" => path,
      "httpOnly" => http_only,
      "secure" => secure,
      "sameSite" => same_site
    }

    params = %{
      "cookie" => cookie,
      "partition" => %{"type" => "context", "context" => session.tab_id}
    }

    case BiDi.command("storage.setCookie", params, bidi_opts(session)) do
      {:ok, _} ->
        session

      {:error, reason, details} ->
        raise ArgumentError, "browser add_cookie failed: #{reason} (#{inspect(details)})"
    end
  end

  defp evaluate_json(session, expression) do
    with {:ok, result} <- UserContextProcess.evaluate(session.user_context_pid, expression, session.tab_id),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
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
  @spec dialog_timeout_ms(keyword()) :: pos_integer()
  def dialog_timeout_ms(opts) when is_list(opts) do
    case Keyword.fetch(opts, :timeout) do
      {:ok, timeout} when is_integer(timeout) and timeout > 0 ->
        timeout

      {:ok, timeout} ->
        raise ArgumentError, "with_dialog/3 :timeout must be a positive integer, got: #{inspect(timeout)}"

      :error ->
        opts
        |> merged_browser_opts()
        |> Keyword.get(:dialog_timeout_ms)
        |> normalize_positive_integer(@default_dialog_timeout_ms)
    end
  end

  @doc false
  @spec popup_timeout_ms(keyword()) :: pos_integer()
  def popup_timeout_ms(opts) when is_list(opts) do
    case Keyword.get(opts, :timeout, @default_popup_timeout_ms) do
      timeout when is_integer(timeout) and timeout > 0 ->
        timeout

      timeout ->
        raise ArgumentError, "with_popup/4 :timeout must be a positive integer, got: #{inspect(timeout)}"
    end
  end

  defp merged_browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp subscribe_dialog_events!(session) do
    BiDi.subscribe(self(), bidi_opts(session))
  end

  defp subscribe_dialog_protocol_events!(session) do
    case BiDi.command(
           "session.subscribe",
           %{"events" => @dialog_events, "contexts" => [session.tab_id]},
           bidi_opts(session)
         ) do
      {:ok, %{"subscription" => subscription_id}} when is_binary(subscription_id) ->
        subscription_id

      {:ok, payload} ->
        raise ArgumentError, "failed to subscribe to dialog events: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "failed to subscribe to dialog events: #{reason} (#{inspect(details)})"
    end
  end

  defp unsubscribe_dialog_events(session) do
    opts = bidi_opts(session)
    _ = BiDi.unsubscribe(self(), opts)
    :ok
  end

  defp unsubscribe_dialog_protocol_events(subscription_id, session) when is_binary(subscription_id) do
    _ = BiDi.command("session.unsubscribe", %{"subscriptions" => [subscription_id]}, bidi_opts(session))
    :ok
  end

  defp flush_stale_dialog_events(context_id) do
    receive do
      {:cerberus_bidi_event,
       %{
         "method" => method,
         "params" => %{"context" => ^context_id}
       }}
      when method in @dialog_events ->
        flush_stale_dialog_events(context_id)
    after
      0 ->
        :ok
    end
  end

  defp await_dialog_opened_event!(context_id, action_task, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    await_dialog_opened_event_loop(context_id, action_task, deadline, :pending)
  end

  defp await_dialog_opened_event_loop(context_id, action_task, deadline, action_outcome) do
    action_outcome = poll_action_task(action_task, action_outcome)

    now = System.monotonic_time(:millisecond)
    remaining = max(deadline - now, 0)

    if remaining == 0 do
      raise_dialog_open_timeout!(action_outcome)
    else
      wait_ms = min(remaining, @dialog_poll_ms)

      receive do
        {:cerberus_bidi_event,
         %{
           "method" => "browsingContext.userPromptOpened",
           "params" => %{"context" => ^context_id} = params
         }} ->
          {params, action_outcome}

        {:cerberus_bidi_event, _other} ->
          await_dialog_opened_event_loop(context_id, action_task, deadline, action_outcome)
      after
        wait_ms ->
          await_dialog_opened_event_loop(context_id, action_task, deadline, action_outcome)
      end
    end
  end

  defp poll_action_task(_action_task, {:ok, _} = action_outcome), do: action_outcome

  defp poll_action_task(action_task, :pending) do
    Task.yield(action_task, 0) || :pending
  end

  defp raise_dialog_open_timeout!(:pending) do
    raise AssertionError, message: "with_dialog/3 timed out waiting for browsingContext.userPromptOpened"
  end

  defp raise_dialog_open_timeout!({:ok, {:action_result, _result}}) do
    raise AssertionError,
      message: "with_dialog/3 callback completed before browsingContext.userPromptOpened was observed"
  end

  defp raise_dialog_open_timeout!({:ok, {:action_failure, formatted_error}}) do
    raise AssertionError,
      message: "with_dialog/3 callback failed before dialog was observed: #{formatted_error}"
  end

  defp await_dialog_event!(method, context_id, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    await_dialog_event_loop(method, context_id, deadline)
  end

  defp await_dialog_event_loop(method, context_id, deadline) do
    now = System.monotonic_time(:millisecond)
    remaining = max(deadline - now, 0)

    receive do
      {:cerberus_bidi_event, %{"method" => ^method, "params" => %{"context" => ^context_id} = params}} ->
        params

      {:cerberus_bidi_event, _other} ->
        await_dialog_event_loop(method, context_id, deadline)
    after
      remaining ->
        raise AssertionError, message: "with_dialog/3 timed out waiting for #{method}"
    end
  end

  defp handle_dialog_prompt!(session, timeout_ms) do
    params = %{"context" => session.tab_id, "accept" => false}
    opts = Keyword.put(bidi_opts(session), :timeout, timeout_ms)

    case BiDi.command("browsingContext.handleUserPrompt", params, opts) do
      {:ok, _payload} ->
        :ok

      {:error, _reason, %{"error" => "no such alert"}} ->
        :ok

      {:error, reason, details} ->
        raise ArgumentError, "with_dialog/3 failed to handle prompt: #{reason} (#{inspect(details)})"
    end
  end

  defp await_dialog_action_result!(_action_task, {:ok, action_outcome}, _timeout_ms) do
    unwrap_dialog_action_outcome!(action_outcome)
  end

  defp await_dialog_action_result!(action_task, :pending, timeout_ms) do
    wait_ms = timeout_ms + 1_000

    case Task.yield(action_task, wait_ms) || Task.shutdown(action_task, :brutal_kill) do
      {:ok, action_outcome} ->
        unwrap_dialog_action_outcome!(action_outcome)

      {:exit, reason} ->
        raise AssertionError, message: "with_dialog/3 callback failed: #{Exception.format_exit(reason)}"

      nil ->
        raise AssertionError, message: "with_dialog/3 timed out waiting for action callback completion"
    end
  end

  defp run_dialog_action(action, session) do
    {:action_result, action.(session)}
  rescue
    error ->
      {:action_failure, Exception.format(:error, error, __STACKTRACE__)}
  catch
    kind, reason ->
      {:action_failure, Exception.format(kind, reason, __STACKTRACE__)}
  end

  defp unwrap_dialog_action_outcome!({:action_result, result}), do: result

  defp unwrap_dialog_action_outcome!({:action_failure, formatted_error}) do
    raise AssertionError, message: "with_dialog/3 callback failed: #{formatted_error}"
  end

  defp await_popup_tab!(session, baseline_tabs, trigger_task, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    await_popup_tab_loop(session, baseline_tabs, trigger_task, deadline, :pending)
  end

  defp await_popup_tab_loop(session, baseline_tabs, trigger_task, deadline, trigger_outcome) do
    trigger_outcome = poll_action_task(trigger_task, trigger_outcome)

    case trigger_outcome do
      {:ok, {:action_failure, formatted_error}} ->
        raise AssertionError, message: "with_popup/4 trigger callback failed before popup capture: #{formatted_error}"

      _ ->
        :ok
    end

    current_tabs = MapSet.new(popup_capture_tabs(session, baseline_tabs))
    new_tabs = current_tabs |> MapSet.difference(baseline_tabs) |> MapSet.to_list()

    case new_tabs do
      [popup_tab_id] ->
        {popup_tab_id, trigger_outcome}

      [] ->
        now = System.monotonic_time(:millisecond)
        remaining = max(deadline - now, 0)

        if remaining == 0 do
          raise AssertionError, message: "with_popup/4 timed out waiting for popup tab"
        else
          Process.sleep(min(remaining, @popup_poll_ms))
          await_popup_tab_loop(session, baseline_tabs, trigger_task, deadline, trigger_outcome)
        end

      multiple_tabs ->
        sorted_tabs = Enum.sort(multiple_tabs)

        raise AssertionError,
          message: "with_popup/4 observed multiple new tabs while capturing popup: #{inspect(sorted_tabs)}"
    end
  end

  defp popup_capture_tabs(session, baseline_tabs) do
    case popup_capture_tabs_from_tree(session, baseline_tabs) do
      {:ok, tabs} ->
        tabs

      {:error, _reason} ->
        UserContextProcess.tabs(session.user_context_pid)
    end
  end

  defp popup_capture_tabs_from_tree(session, baseline_tabs) do
    with {:ok, %{"contexts" => contexts}} when is_list(contexts) <-
           BiDi.command("browsingContext.getTree", %{"maxDepth" => 0}, bidi_opts(session)),
         entries when is_list(entries) <- flatten_tree_context_entries(contexts),
         user_context when is_binary(user_context) and user_context != "" <-
           infer_user_context(entries, baseline_tabs) do
      tabs =
        entries
        |> Enum.filter(&(&1.user_context == user_context))
        |> Enum.map(& &1.context_id)
        |> Enum.uniq()

      {:ok, tabs}
    else
      {:error, reason, details} ->
        {:error, "browsingContext.getTree failed: #{reason} (#{inspect(details)})"}

      _ ->
        {:error, "unable to resolve user context for popup capture"}
    end
  end

  defp flatten_tree_context_entries(contexts) when is_list(contexts) do
    Enum.flat_map(contexts, &flatten_tree_context_entry/1)
  end

  defp flatten_tree_context_entries(nil), do: []

  defp flatten_tree_context_entry(%{"context" => context_id} = entry) when is_binary(context_id) do
    children = flatten_tree_context_entries(Map.get(entry, "children", []))
    [%{context_id: context_id, user_context: entry["userContext"]} | children]
  end

  defp flatten_tree_context_entry(_entry), do: []

  defp infer_user_context(entries, baseline_tabs) do
    Enum.find_value(entries, fn %{context_id: context_id, user_context: user_context} ->
      if MapSet.member?(baseline_tabs, context_id) and is_binary(user_context) and user_context != "" do
        user_context
      end
    end)
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

  defp assert_dialog_message!(_observed, nil), do: :ok

  defp assert_dialog_message!(%{message: actual}, expected) when is_binary(expected) do
    if actual != expected do
      raise AssertionError,
        message: "with_dialog/3 expected message #{inspect(expected)} but observed #{inspect(actual)}"
    end
  end

  defp host_from_base_url(base_url) when is_binary(base_url) do
    case URI.parse(base_url) do
      %URI{host: host} when is_binary(host) and host != "" -> host
      _ -> raise ArgumentError, "could not infer cookie domain from base URL: #{inspect(base_url)}"
    end
  end

  defp normalize_same_site(value) when value in [:lax, "lax", :strict, "strict", :none, "none"] do
    value
    |> to_string()
    |> String.downcase()
  end

  defp normalize_same_site(value) do
    raise ArgumentError,
          "add_cookie/4 :same_site must be :lax, :strict, :none (or lowercase strings), got: #{inspect(value)}"
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
