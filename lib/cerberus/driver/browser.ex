defmodule Cerberus.Driver.Browser do
  @moduledoc """
  Browser driver adapter backed by WebDriver BiDi.
  Cerberus treats BiDi as the primary browser protocol (not CDP).

  Supervision topology (see ADR-0004):

      Cerberus.Driver.Browser.Supervisor (rest_for_one)
      |- Cerberus.Driver.Browser.Runtime
      |- Cerberus.Driver.Browser.BiDiSupervisor (one_for_all)
      |  |- Cerberus.Driver.Browser.BiDiSocket
      |  `- Cerberus.Driver.Browser.BiDi
      `- Cerberus.Driver.Browser.UserContextSupervisor (DynamicSupervisor)
         `- Cerberus.Driver.Browser.UserContextProcess (per test, temporary)
            `- Cerberus.Driver.Browser.BrowsingContextSupervisor
               `- Cerberus.Driver.Browser.BrowsingContextProcess (per browsingContext, temporary)

  Restart behavior:
  - `rest_for_one` at the top level restarts transport and test-scoped workers when runtime fails.
  - `one_for_all` in `BiDiSupervisor` restarts socket and connection together.
  - `UserContextProcess` and `BrowsingContextProcess` are temporary to avoid silent self-healing in tests.
  """

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Locator
  alias Cerberus.Query
  alias Cerberus.Session

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @user_context_supervisor Cerberus.Driver.Browser.UserContextSupervisor

  @type t :: %__MODULE__{
          user_context_pid: pid(),
          base_url: String.t(),
          ready_timeout_ms: pos_integer(),
          ready_quiet_ms: pos_integer(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct user_context_pid: nil,
            base_url: nil,
            ready_timeout_ms: @default_ready_timeout_ms,
            ready_quiet_ms: @default_ready_quiet_ms,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    owner = self()
    start_opts = Keyword.put(opts, :owner, owner)

    {user_context_pid, base_url} =
      case start_user_context(start_opts) do
        {:ok, user_context_pid} ->
          {user_context_pid, UserContextProcess.base_url(user_context_pid)}

        {:error, reason} ->
          raise ArgumentError, "failed to initialize browser driver: #{inspect(reason)}"
      end

    %__MODULE__{
      user_context_pid: user_context_pid,
      base_url: base_url,
      ready_timeout_ms: ready_timeout_ms(opts),
      ready_quiet_ms: ready_quiet_ms(opts)
    }
  end

  @impl true
  def visit(%__MODULE__{} = session, path, _opts) do
    state = state!(session)
    url = to_absolute_url(state.base_url, path)

    case UserContextProcess.navigate(state.user_context_pid, url) do
      {:ok, _} ->
        case with_snapshot(state) do
          {state, snapshot} ->
            update_session(session, state, :visit, %{path: snapshot.path, title: snapshot.title})

          {:error, reason, details} ->
            raise ArgumentError,
                  "failed to collect browser snapshot after visit: #{reason} (#{inspect(details)})"
        end

      {:error, reason, details} ->
        raise ArgumentError, "browser navigate failed: #{reason} (#{inspect(details)})"
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)

    with_driver_ready(session, state, :click, fn ready_state ->
      case clickables(ready_state) do
        {:ok, clickables_data} ->
          do_click(session, ready_state, clickables_data, expected, opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect clickable elements: #{reason}"}
      end
    end)
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, value, opts) do
    state = state!(session)

    with_driver_ready(session, state, :fill_in, fn ready_state ->
      case form_fields(ready_state) do
        {:ok, fields_data} ->
          do_fill_in(session, ready_state, fields_data, expected, value, opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect form fields: #{reason}"}
      end
    end)
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)

    with_driver_ready(session, state, :submit, fn ready_state ->
      case clickables(ready_state) do
        {:ok, clickables_data} ->
          do_submit(session, ready_state, clickables_data, expected, opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect submit controls: #{reason}"}
      end
    end)
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)
    visible = Keyword.get(opts, :visible, true)

    with_driver_ready(session, state, :assert_has, fn ready_state ->
      case with_snapshot(ready_state) do
        {next_state, snapshot} ->
          assert_snapshot_result(session, next_state, snapshot, expected, visible, opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to collect browser text snapshot: #{reason}"}
      end
    end)
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)
    visible = Keyword.get(opts, :visible, true)

    with_driver_ready(session, state, :refute_has, fn ready_state ->
      case with_snapshot(ready_state) do
        {next_state, snapshot} ->
          refute_snapshot_result(session, next_state, snapshot, expected, visible, opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to collect browser text snapshot: #{reason}"}
      end
    end)
  end

  defp do_click(session, state, clickables_data, expected, opts) do
    kind = Keyword.get(opts, :kind, :any)
    links = Map.get(clickables_data, "links", [])
    buttons = Map.get(clickables_data, "buttons", [])

    link =
      if kind == :button do
        nil
      else
        Enum.find(links, &Query.match_text?(&1["text"] || "", expected, opts))
      end

    if link == nil do
      button =
        if kind == :link do
          nil
        else
          Enum.find(buttons, &Query.match_text?(&1["text"] || "", expected, opts))
        end

      if button == nil do
        observed = %{action: :click, path: state.current_path, clickables: clickables_data}
        {:error, session, observed, no_clickable_error(kind)}
      else
        click_button(session, state, button)
      end
    else
      click_link(session, state, link)
    end
  end

  defp do_submit(session, state, clickables_data, expected, opts) do
    buttons =
      clickables_data
      |> Map.get("buttons", [])
      |> Enum.filter(&submit_control?/1)

    case find_matching_by_text(buttons, expected, opts) do
      nil ->
        observed = %{action: :submit, path: state.current_path, clickables: clickables_data}
        {:error, session, observed, "no submit button matched locator"}

      button ->
        submit_button(session, state, button)
    end
  end

  defp do_fill_in(session, state, fields_data, expected, value, opts) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_by_label(fields, expected, opts) do
      nil ->
        observed = %{action: :fill_in, path: state.current_path, fields: fields_data}
        {:error, session, observed, "no form field matched locator"}

      field ->
        fill_field(session, state, field, value)
    end
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

  defp submit_button(session, state, button) do
    index = button["index"] || 0
    expression = submit_target_expression(index)

    case eval_json(state.user_context_pid, expression) do
      {:ok, %{"ok" => true, "url" => url}} ->
        navigate_submit_target(session, state, button, url)

      {:ok, result} ->
        reason = Map.get(result, "reason", "submit_target_failed")
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, result: result}
        {:error, session, observed, "browser submit failed: #{reason}"}

      {:error, reason, details} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser submit failed: #{reason}"}
    end
  end

  defp navigate_submit_target(session, state, button, url) do
    case UserContextProcess.navigate(state.user_context_pid, url) do
      {:ok, _} ->
        submit_snapshot_result(session, state, button)

      {:error, reason, details} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser submit navigation failed: #{reason}"}
    end
  end

  defp submit_snapshot_result(session, state, button) do
    case with_snapshot(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :submit,
          clicked: button["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden
        }

        {:ok, update_session(session, next_state, :submit, observed), observed}

      {:error, reason, details} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect page after submit: #{reason}"}
    end
  end

  defp fill_field(session, state, field, value) do
    index = field["index"] || 0
    expression = field_set_expression(index, value)

    case eval_json(state.user_context_pid, expression) do
      {:ok, result} ->
        fill_field_result(session, state, field, value, result)

      {:error, reason, details} ->
        observed = %{action: :fill_in, path: state.current_path, field: field, details: details}
        {:error, session, observed, "browser field fill failed: #{reason}"}
    end
  end

  defp fill_field_result(session, state, field, value, result) do
    if Map.get(result, "ok", false) do
      case await_driver_ready(state) do
        {:ok, readiness} ->
          observed = %{
            action: :fill_in,
            path: Map.get(result, "path", state.current_path),
            field: field,
            value: value,
            readiness: readiness
          }

          {:ok, update_last_result(session, :fill_in, observed), observed}

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
    else
      reason = Map.get(result, "reason", "field_fill_failed")
      observed = %{action: :fill_in, path: state.current_path, field: field, result: result}
      {:error, session, observed, "browser field fill failed: #{reason}"}
    end
  end

  defp navigate_link(session, state, link, url) do
    case UserContextProcess.navigate(state.user_context_pid, url) do
      {:ok, _} ->
        link_snapshot_result(session, state, link)

      {:error, reason, details} ->
        observed = %{action: :link, clicked: link["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser link navigation failed: #{reason}"}
    end
  end

  defp link_snapshot_result(session, state, link) do
    case with_snapshot(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :link,
          clicked: link["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden
        }

        {:ok, update_session(session, next_state, :click, observed), observed}

      {:error, reason, details} ->
        observed = %{action: :link, clicked: link["text"], path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect page after link click: #{reason}"}
    end
  end

  defp find_matching_by_text(items, expected, opts) do
    Enum.find(items, &Query.match_text?(&1["text"] || "", expected, opts))
  end

  defp find_matching_by_label(items, expected, opts) do
    Enum.find(items, &Query.match_text?(&1["label"] || "", expected, opts))
  end

  defp submit_control?(button) do
    type = (button["type"] || "submit") |> to_string() |> String.downcase()
    type in ["submit", ""]
  end

  defp click_button(session, state, button) do
    index = button["index"] || 0
    expression = button_click_expression(index)

    case eval_json(state.user_context_pid, expression) do
      {:ok, _result} ->
        click_button_after_eval(session, state, button)

      {:error, reason, details} ->
        observed = %{action: :button, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser button click failed: #{reason}"}
    end
  end

  defp clickables(state) do
    eval_json(state.user_context_pid, clickables_expression())
  end

  defp form_fields(state) do
    eval_json(state.user_context_pid, form_fields_expression())
  end

  defp with_snapshot(state) do
    case eval_json(state.user_context_pid, snapshot_expression()) do
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

  defp eval_json(user_context_pid, expression) do
    with {:ok, result} <- UserContextProcess.evaluate(user_context_pid, expression),
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

    case UserContextProcess.await_ready(state.user_context_pid, opts) do
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
      String.contains?(combined, "Cannot find context with specified id")
  end

  defp readiness_payload?(payload) when is_map(payload) do
    Map.has_key?(payload, "awaited") or Map.has_key?(payload, "lastSignal")
  end

  defp assert_snapshot_result(session, next_state, snapshot, expected, visible, opts) do
    texts = select_texts(snapshot, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: snapshot.path,
      title: snapshot.title,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:error, session, observed, "expected text not found"}
    else
      {:ok, update_session(session, next_state, :assert_has, observed), observed}
    end
  end

  defp refute_snapshot_result(session, next_state, snapshot, expected, visible, opts) do
    texts = select_texts(snapshot, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: snapshot.path,
      title: snapshot.title,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:ok, update_session(session, next_state, :refute_has, observed), observed}
    else
      {:error, session, observed, "unexpected matching text found"}
    end
  end

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
    cond do
      is_map(details) and navigation_transition_error?(reason, details) ->
        {:ok, navigation_transition_readiness(details)}

      is_map(details) and readiness_payload?(details) ->
        {:error, reason, details}

      true ->
        {:error, reason, merge_last_readiness(state, details)}
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
      case UserContextProcess.last_readiness(state.user_context_pid) do
        %{} = last when map_size(last) > 0 -> last
        _ -> %{}
      end

    Map.put_new(readiness, "details", details)
  end

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

  defp select_texts(snapshot, true), do: snapshot.visible
  defp select_texts(snapshot, false), do: snapshot.hidden
  defp select_texts(snapshot, :any), do: snapshot.visible ++ snapshot.hidden

  defp state!(%__MODULE__{user_context_pid: user_context_pid} = state) when is_pid(user_context_pid), do: state
  defp state!(_), do: raise(ArgumentError, "browser driver state is not initialized")

  defp update_session(%__MODULE__{} = session, %{} = state, op, observed) do
    %{
      session
      | user_context_pid: state.user_context_pid,
        base_url: state.base_url,
        ready_timeout_ms: state.ready_timeout_ms,
        ready_quiet_ms: state.ready_quiet_ms,
        current_path: state.current_path,
        last_result: %{op: op, observed: observed}
    }
  end

  defp update_last_result(%__MODULE__{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp to_absolute_url(base_url, path_or_url) do
    uri = URI.parse(path_or_url)

    if is_binary(uri.scheme) do
      path_or_url
    else
      base_uri = URI.parse(base_url)
      base_uri |> URI.merge(path_or_url) |> to_string()
    end
  end

  defp start_user_context(opts) do
    case Process.whereis(@user_context_supervisor) do
      nil ->
        UserContextProcess.start_link(opts)

      supervisor_pid ->
        DynamicSupervisor.start_child(supervisor_pid, {UserContextProcess, opts})
    end
  end

  defp ready_timeout_ms(opts) do
    opts
    |> Keyword.get(:ready_timeout_ms, @default_ready_timeout_ms)
    |> normalize_positive_integer(@default_ready_timeout_ms)
  end

  defp ready_quiet_ms(opts) do
    opts |> Keyword.get(:ready_quiet_ms, @default_ready_quiet_ms) |> normalize_positive_integer(@default_ready_quiet_ms)
  end

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp snapshot_expression do
    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const isHidden = (node) => {
        let current = node.parentElement;
        while (current) {
          if (current.hasAttribute("hidden")) return true;
          const style = window.getComputedStyle(current);
          if (style.display === "none" || style.visibility === "hidden") return true;
          current = current.parentElement;
        }
        return false;
      };

      const visible = [];
      const hidden = [];
      const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT);
      while (walker.nextNode()) {
        const node = walker.currentNode;
        const value = normalize(node.nodeValue);
        if (!value) continue;
        if (isHidden(node)) {
          hidden.push(value);
        } else {
          visible.push(value);
        }
      }

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        visible,
        hidden
      });
    })()
    """
  end

  defp clickables_expression do
    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const links = Array.from(document.querySelectorAll("a[href]")).map((element, index) => ({
        index,
        text: normalize(element.textContent),
        href: element.getAttribute("href") || "",
        resolvedHref: element.href || ""
      }));

      const buttons = Array.from(document.querySelectorAll("button")).map((element, index) => ({
        index,
        text: normalize(element.textContent),
        type: (element.getAttribute("type") || "submit").toLowerCase(),
        name: element.getAttribute("name") || "",
        value: element.getAttribute("value") || ""
      }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        links,
        buttons
      });
    })()
    """
  end

  defp form_fields_expression do
    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const labels = new Map();

      Array.from(document.querySelectorAll("label[for]")).forEach((label) => {
        const id = label.getAttribute("for");
        if (id) labels.set(id, normalize(label.textContent));
      });

      const fields = Array.from(document.querySelectorAll("input, textarea, select"))
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button";
        })
        .map((element, index) => ({
          index,
          id: element.id || "",
          name: element.name || "",
          label: labels.get(element.id) || ""
        }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        fields
      });
    })()
    """
  end

  defp field_set_expression(index, value) do
    encoded_value = JSON.encode!(to_string(value))

    """
    (() => {
      const fields = Array.from(document.querySelectorAll("input, textarea, select"))
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button";
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const value = #{encoded_value};
      field.value = value;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end

  defp submit_target_expression(index) do
    """
    (() => {
      const buttons = Array.from(document.querySelectorAll("button"));
      const button = buttons[#{index}];

      if (!button) {
        return JSON.stringify({ ok: false, reason: "button_not_found" });
      }

      const form = button.form;
      if (!form) {
        return JSON.stringify({ ok: false, reason: "button_has_no_form" });
      }

      const method = (button.getAttribute("formmethod") || form.getAttribute("method") || "get").toLowerCase();
      if (method !== "get") {
        return JSON.stringify({ ok: false, reason: "unsupported_method", method });
      }

      const action = button.getAttribute("formaction") || form.getAttribute("action") || window.location.pathname;
      const target = new URL(action, window.location.href);

      let formData;
      try {
        formData = new FormData(form, button);
      } catch (_error) {
        formData = new FormData(form);
        const type = (button.getAttribute("type") || "submit").toLowerCase();
        const name = button.getAttribute("name");
        if ((type === "submit" || type === "") && name) {
          formData.append(name, button.getAttribute("value") || "");
        }
      }

      const params = new URLSearchParams(formData);
      const query = params.toString();
      target.search = query;

      return JSON.stringify({
        ok: true,
        url: target.toString(),
        path: target.pathname + target.search
      });
    })()
    """
  end

  defp button_click_expression(index) do
    """
    (() => {
      const buttons = Array.from(document.querySelectorAll("button"));
      const button = buttons[#{index}];

      if (!button) {
        return JSON.stringify({ ok: false, reason: "button_not_found" });
      }

      button.click();

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end
end
