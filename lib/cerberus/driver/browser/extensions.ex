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

  @spec type(BrowserSession.t(), String.t(), keyword()) :: BrowserSession.t()
  def type(%BrowserSession{} = session, text, opts \\ []) when is_binary(text) and is_list(opts) do
    selector = selector_opt!(opts)
    clear? = Keyword.get(opts, :clear, false)

    case evaluate_json(session, type_expression(selector, text, clear?)) do
      {:ok, %{"ok" => true} = payload} ->
        update_last_result(session, :type, payload)

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
      {:ok, %{"ok" => true} = payload} ->
        update_last_result(session, :press, payload)

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
      {:ok, %{"ok" => true} = payload} ->
        update_last_result(session, :drag, payload)

      {:ok, payload} ->
        raise ArgumentError, "browser drag failed: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "browser drag failed: #{reason} (#{inspect(details)})"
    end
  end

  @spec with_dialog(BrowserSession.t(), (BrowserSession.t() -> BrowserSession.t()), keyword()) ::
          BrowserSession.t()
  def with_dialog(%BrowserSession{} = session, action, opts \\ []) when is_function(action, 1) and is_list(opts) do
    timeout_ms = dialog_timeout_ms(opts)
    expected_message = Keyword.get(opts, :message)

    subscription_id = subscribe_dialog_events!(session)
    action_task = Task.async(fn -> action.(session) end)

    try do
      opened = await_dialog_event!("browsingContext.userPromptOpened", session.tab_id, timeout_ms)
      handle_dialog_prompt!(session, timeout_ms)
      closed = await_dialog_event!("browsingContext.userPromptClosed", session.tab_id, timeout_ms)
      next_session = await_dialog_action_result!(action_task, timeout_ms)

      if !match?(%BrowserSession{}, next_session) do
        raise ArgumentError, "with_dialog/3 callback must return a browser session"
      end

      observed = %{
        type: opened["type"],
        message: opened["message"],
        handler: opened["handler"],
        accepted: Map.get(closed, "accepted", false)
      }

      assert_dialog_message!(observed, expected_message)
      update_last_result(next_session, :with_dialog, observed)
    after
      _ = Task.shutdown(action_task, :brutal_kill)
      unsubscribe_dialog_events(subscription_id, session)
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
        update_last_result(session, :add_cookie, %{
          name: name,
          value: value,
          domain: domain,
          path: path,
          http_only: http_only,
          secure: secure,
          same_site: same_site
        })

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

  defp merged_browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp subscribe_dialog_events!(session) do
    bidi_opts = bidi_opts(session)
    :ok = BiDi.subscribe(self(), bidi_opts)

    case BiDi.command("session.subscribe", %{"events" => @dialog_events, "contexts" => [session.tab_id]}, bidi_opts) do
      {:ok, %{"subscription" => subscription_id}} when is_binary(subscription_id) ->
        subscription_id

      {:ok, payload} ->
        raise ArgumentError, "failed to subscribe to dialog events: #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "failed to subscribe to dialog events: #{reason} (#{inspect(details)})"
    end
  end

  defp unsubscribe_dialog_events(subscription_id, session) do
    opts = bidi_opts(session)
    _ = BiDi.command("session.unsubscribe", %{"subscriptions" => [subscription_id]}, opts)
    _ = BiDi.unsubscribe(self(), opts)
    :ok
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

      {:error, reason, details} ->
        raise ArgumentError, "with_dialog/3 failed to handle prompt: #{reason} (#{inspect(details)})"
    end
  end

  defp await_dialog_action_result!(action_task, timeout_ms) do
    wait_ms = timeout_ms + 1_000

    case Task.yield(action_task, wait_ms) || Task.shutdown(action_task, :brutal_kill) do
      {:ok, result} ->
        result

      {:exit, reason} ->
        raise AssertionError, message: "with_dialog/3 callback failed: #{Exception.format_exit(reason)}"

      nil ->
        raise AssertionError, message: "with_dialog/3 timed out waiting for action callback completion"
    end
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

  defp update_last_result(session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
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
