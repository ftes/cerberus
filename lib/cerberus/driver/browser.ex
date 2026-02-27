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

  @user_context_supervisor Cerberus.Driver.Browser.UserContextSupervisor

  @type state :: %{
          user_context_pid: pid(),
          base_url: String.t(),
          path: String.t() | nil
        }

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

    %Session{
      driver: :browser,
      driver_state: %{user_context_pid: user_context_pid, base_url: base_url, path: nil},
      meta: Map.new(opts)
    }
  end

  @impl true
  def visit(%Session{} = session, path, _opts) do
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
  def click(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)

    case clickables(state) do
      {:ok, clickables_data} ->
        do_click(session, state, clickables_data, expected, opts)

      {:error, reason, details} ->
        observed = %{path: state.path, details: details}
        {:error, session, observed, "failed to inspect clickable elements: #{reason}"}
    end
  end

  @impl true
  def assert_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)
    visible = Keyword.get(opts, :visible, true)

    case with_snapshot(state) do
      {state, snapshot} ->
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

        if matched != [] do
          {:ok, update_session(session, state, :assert_has, observed), observed}
        else
          {:error, session, observed, "expected text not found"}
        end

      {:error, reason, details} ->
        observed = %{path: state.path, details: details}
        {:error, session, observed, "failed to collect browser text snapshot: #{reason}"}
    end
  end

  @impl true
  def refute_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)
    visible = Keyword.get(opts, :visible, true)

    case with_snapshot(state) do
      {state, snapshot} ->
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
          {:ok, update_session(session, state, :refute_has, observed), observed}
        else
          {:error, session, observed, "unexpected matching text found"}
        end

      {:error, reason, details} ->
        observed = %{path: state.path, details: details}
        {:error, session, observed, "failed to collect browser text snapshot: #{reason}"}
    end
  end

  defp do_click(session, state, clickables_data, expected, opts) do
    links = Map.get(clickables_data, "links", [])
    buttons = Map.get(clickables_data, "buttons", [])

    case Enum.find(links, &Query.match_text?(&1["text"] || "", expected, opts)) do
      nil ->
        case Enum.find(buttons, &Query.match_text?(&1["text"] || "", expected, opts)) do
          nil ->
            observed = %{action: :click, path: state.path, clickables: clickables_data}
            {:error, session, observed, "no clickable element matched locator"}

          button ->
            click_button(session, state, button)
        end

      link ->
        click_link(session, state, link)
    end
  end

  defp click_link(session, state, link) do
    url = link["resolvedHref"] || link["href"] || ""

    if url == "" do
      observed = %{action: :link, path: state.path, clicked: link["text"], link: link}
      {:error, session, observed, "matched link has no href"}
    else
      case UserContextProcess.navigate(state.user_context_pid, url) do
        {:ok, _} ->
          case with_snapshot(state) do
            {state, snapshot} ->
              observed = %{
                action: :link,
                clicked: link["text"],
                path: snapshot.path,
                title: snapshot.title,
                texts: snapshot.visible ++ snapshot.hidden
              }

              {:ok, update_session(session, state, :click, observed), observed}

            {:error, reason, details} ->
              observed = %{
                action: :link,
                clicked: link["text"],
                path: state.path,
                details: details
              }

              {:error, session, observed, "failed to inspect page after link click: #{reason}"}
          end

        {:error, reason, details} ->
          observed = %{action: :link, clicked: link["text"], path: state.path, details: details}
          {:error, session, observed, "browser link navigation failed: #{reason}"}
      end
    end
  end

  defp click_button(session, state, button) do
    index = button["index"] || 0
    expression = button_click_expression(index)

    case eval_json(state.user_context_pid, expression) do
      {:ok, _result} ->
        case with_settled_snapshot(state) do
          {state, snapshot} ->
            observed = %{
              action: :button,
              clicked: button["text"],
              path: snapshot.path,
              title: snapshot.title,
              texts: snapshot.visible ++ snapshot.hidden
            }

            {:ok, update_session(session, state, :click, observed), observed}

          {:error, reason, details} ->
            observed = %{
              action: :button,
              clicked: button["text"],
              path: state.path,
              details: details
            }

            {:error, session, observed, "failed to inspect page after button click: #{reason}"}
        end

      {:error, reason, details} ->
        observed = %{action: :button, clicked: button["text"], path: state.path, details: details}
        {:error, session, observed, "browser button click failed: #{reason}"}
    end
  end

  defp clickables(state) do
    eval_json(state.user_context_pid, clickables_expression())
  end

  defp with_settled_snapshot(state, attempts \\ 20, delay_ms \\ 50) do
    case with_snapshot(state) do
      {state, snapshot} ->
        settle_snapshot(state, snapshot, attempts, delay_ms)

      {:error, _, _} = error ->
        error
    end
  end

  defp settle_snapshot(state, snapshot, 0, _delay_ms), do: {state, snapshot}

  defp settle_snapshot(state, snapshot, attempts, delay_ms) do
    Process.sleep(delay_ms)

    case with_snapshot(state) do
      {next_state, next_snapshot} ->
        if snapshots_equal?(snapshot, next_snapshot) do
          {next_state, next_snapshot}
        else
          settle_snapshot(next_state, next_snapshot, attempts - 1, delay_ms)
        end

      {:error, _, _} = error ->
        error
    end
  end

  defp snapshots_equal?(left, right) do
    left.path == right.path and
      left.title == right.title and
      left.visible == right.visible and
      left.hidden == right.hidden
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

        {%{state | path: snapshot.path}, snapshot}

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

  defp decode_remote_json(%{"result" => %{"type" => "string", "value" => payload}})
       when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "invalid json payload from browser: #{inspect(reason)}"}
    end
  end

  defp decode_remote_json(result) do
    {:error, "unexpected script.evaluate result: #{inspect(result)}"}
  end

  defp select_texts(snapshot, true), do: snapshot.visible
  defp select_texts(snapshot, false), do: snapshot.hidden
  defp select_texts(snapshot, :any), do: snapshot.visible ++ snapshot.hidden

  defp state!(%Session{driver_state: %{} = state}), do: state
  defp state!(_), do: raise(ArgumentError, "browser driver state is not initialized")

  defp update_session(%Session{} = session, %{} = state, op, observed) do
    %Session{
      session
      | driver_state: state,
        current_path: state.path,
        last_result: %{op: op, observed: observed}
    }
  end

  defp to_absolute_url(base_url, path_or_url) do
    uri = URI.parse(path_or_url)

    if is_binary(uri.scheme) do
      path_or_url
    else
      base_uri = URI.parse(base_url)
      URI.merge(base_uri, path_or_url) |> to_string()
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
        text: normalize(element.textContent)
      }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        links,
        buttons
      });
    })()
    """
  end

  defp button_click_expression(index) do
    """
    (async () => {
      const waitForLiveViewConnected = () => new Promise((resolve) => {
        const roots = () => Array.from(document.querySelectorAll("[data-phx-session]"));
        const connected = () => {
          const currentRoots = roots();
          if (currentRoots.length === 0) return true;
          return currentRoots.every((root) => root.classList.contains("phx-connected"));
        };

        if (connected()) {
          resolve();
          return;
        }

        const observer = new MutationObserver(() => {
          if (connected()) {
            observer.disconnect();
            clearTimeout(timer);
            resolve();
          }
        });

        observer.observe(document.documentElement, {
          subtree: true,
          childList: true,
          attributes: true,
          attributeFilter: ["class"]
        });

        const timer = setTimeout(() => {
          observer.disconnect();
          resolve();
        }, 1500);
      });

      await waitForLiveViewConnected();

      const buttons = Array.from(document.querySelectorAll("button"));
      const button = buttons[#{index}];

      if (!button) {
        return JSON.stringify({ ok: false, reason: "button_not_found" });
      }

      await new Promise((resolve) => {
        let settled = false;
        const finish = () => {
          if (settled) return;
          settled = true;
          observer.disconnect();
          window.removeEventListener("load", finish);
          clearTimeout(timer);
          resolve();
        };

        const observer = new MutationObserver(() => finish());
        observer.observe(document.documentElement, {
          subtree: true,
          childList: true,
          attributes: true,
          characterData: true
        });

        window.addEventListener("load", finish, { once: true });
        const timer = setTimeout(finish, 1000);
        button.click();
      });

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end
end
