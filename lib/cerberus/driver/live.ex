defmodule Cerberus.Driver.Live do
  @moduledoc "Live driver adapter backed by a real Phoenix endpoint via LiveViewTest."

  @behaviour Cerberus.Driver

  import Phoenix.LiveViewTest, only: [element: 3, render: 1, render_click: 1]

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Html
  alias Cerberus.Locator
  alias Cerberus.Query
  alias Cerberus.Session

  @type state :: %{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          mode: :static | :live,
          view: term() | nil,
          html: String.t(),
          path: String.t() | nil,
          form_data: map()
        }

  @impl true
  def new_session(opts \\ []) do
    endpoint = Conn.endpoint!(opts)

    %Session{
      driver: :live,
      driver_state: %{
        endpoint: endpoint,
        conn: nil,
        mode: :static,
        view: nil,
        html: "",
        path: nil,
        form_data: empty_form_data()
      },
      meta: Map.new(opts)
    }
  end

  @impl true
  def visit(%Session{} = session, path, _opts) do
    state = state!(session)
    conn = Conn.ensure_conn(state.conn)
    conn = Conn.follow_get(state.endpoint, conn, path)
    current_path = Conn.current_path(conn, path)

    {mode, view, html} =
      case try_live(conn) do
        {:ok, view, html} ->
          {:live, view, html}

        :error ->
          {:static, nil, conn.resp_body || ""}
      end

    update_session(
      session,
      %{state | conn: conn, mode: mode, view: view, html: html, path: current_path},
      :visit,
      %{
        path: current_path,
        mode: mode
      }
    )
  end

  @impl true
  def click(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))
    kind = Keyword.get(opts, :kind, :any)

    case find_clickable_link(state, expected, opts, kind) do
      {:ok, link} when is_binary(link.href) ->
        updated = visit(session, link.href, [])
        updated_state = state!(updated)

        observed = %{
          action: :link,
          path: updated_state.path,
          mode: updated_state.mode,
          clicked: link.text,
          texts: Html.texts(updated_state.html, :any)
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      :error ->
        case find_clickable_button(state, expected, opts, kind) do
          {:ok, button} when state.mode == :live and state.view != nil ->
            click_live_button(session, state, button)

          {:ok, button} ->
            observed = %{
              action: :button,
              clicked: button.text,
              path: state.path,
              mode: state.mode
            }

            {:error, session, observed, click_button_error(kind)}

          :error ->
            observed = %{
              action: :click,
              path: state.path,
              mode: state.mode,
              texts: Html.texts(state.html, :any)
            }

            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%Session{} = session, %Locator{kind: :text, value: expected}, value, opts) do
    state = with_latest_html(state!(session))

    case state.mode do
      :live ->
        observed = %{action: :fill_in, path: state.path, mode: state.mode}
        {:error, session, observed, "live driver does not yet support fill_in on live routes"}

      :static ->
        case Html.find_form_field(state.html, expected, opts) do
          {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
            updated_state = %{state | form_data: put_form_value(state.form_data, field.form, name, value)}

            observed = %{
              action: :fill_in,
              path: state.path,
              mode: state.mode,
              field: field,
              value: value
            }

            {:ok, update_session(session, updated_state, :fill_in, observed), observed}

          {:ok, _field} ->
            observed = %{action: :fill_in, path: state.path, mode: state.mode}
            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{action: :fill_in, path: state.path, mode: state.mode}
            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def submit(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))

    case state.mode do
      :live ->
        observed = %{action: :submit, path: state.path, mode: state.mode}
        {:error, session, observed, "live driver does not yet support submit on live routes"}

      :static ->
        case Html.find_submit_button(state.html, expected, opts) do
          {:ok, button} ->
            do_submit(session, state, button)

          :error ->
            observed = %{action: :submit, path: state.path, mode: state.mode}
            {:error, session, observed, "no submit button matched locator"}
        end
    end
  end

  @impl true
  def assert_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(state.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: state.path,
      mode: state.mode,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:error, session, observed, "expected text not found"}
    else
      {:ok, update_session(session, state, :assert_has, observed), observed}
    end
  end

  @impl true
  def refute_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(state.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: state.path,
      mode: state.mode,
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
  end

  defp click_live_button(session, state, button) do
    result =
      state.view
      |> element("button", button.text)
      |> render_click()

    case result do
      rendered when is_binary(rendered) ->
        path = maybe_live_patch_path(state.view, state.path)
        updated_state = %{state | html: rendered, path: path}

        observed = %{
          action: :button,
          clicked: button.text,
          path: path,
          mode: :live,
          texts: Html.texts(rendered, :any)
        }

        {:ok, update_session(session, updated_state, :click, observed), observed}

      {:error, {:live_redirect, %{to: to}}} ->
        redirected_result(session, button, to)

      {:error, {:redirect, %{to: to}}} ->
        redirected_result(session, button, to)

      {:error, {:live_patch, %{to: to}}} ->
        rendered = render(state.view)
        updated_state = %{state | html: rendered, path: to}

        observed = %{
          action: :button,
          clicked: button.text,
          path: to,
          mode: :live,
          texts: Html.texts(rendered, :any)
        }

        {:ok, update_session(session, updated_state, :click, observed), observed}

      other ->
        observed = %{
          action: :button,
          clicked: button.text,
          path: state.path,
          mode: state.mode,
          result: other
        }

        {:error, session, observed, "unexpected live click result"}
    end
  end

  defp redirected_result(session, button, to) do
    updated = visit(session, to, [])
    updated_state = state!(updated)

    observed = %{
      action: :button,
      clicked: button.text,
      path: updated_state.path,
      mode: updated_state.mode,
      texts: Html.texts(updated_state.html, :any)
    }

    {:ok, update_last_result(updated, :click, observed), observed}
  end

  defp try_live(conn) do
    case Phoenix.LiveViewTest.__live__(conn, nil, []) do
      {:ok, view, html} -> {:ok, view, html}
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp with_latest_html(%{mode: :live, view: view} = state) when not is_nil(view) do
    %{state | html: render(view)}
  end

  defp with_latest_html(state), do: state

  defp state!(%Session{driver_state: %{} = state}), do: state
  defp state!(_), do: raise(ArgumentError, "live driver state is not initialized")

  defp update_session(%Session{} = session, state, op, observed) do
    %{
      session
      | driver_state: state,
        current_path: state.path,
        last_result: %{op: op, observed: observed}
    }
  end

  defp update_last_result(%Session{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp find_clickable_link(_state, _expected, _opts, :button), do: :error

  defp find_clickable_link(state, expected, opts, _kind), do: Html.find_link(state.html, expected, opts)

  defp find_clickable_button(_state, _expected, _opts, :link), do: :error

  defp find_clickable_button(state, expected, opts, _kind), do: Html.find_button(state.html, expected, opts)

  defp click_button_error(:button), do: "live driver can only click buttons on live routes for click_button"

  defp click_button_error(_kind), do: "live driver can only click buttons on live routes"

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp do_submit(session, state, button) do
    method =
      button
      |> Map.get(:method)
      |> to_string()
      |> String.trim()
      |> String.downcase()
      |> case do
        "" -> "get"
        value -> value
      end

    if method == "get" do
      target =
        button
        |> Map.get(:action)
        |> build_submit_target(state.path, params_for_submit(state.form_data, button))

      updated = visit(session, target, [])
      updated_state = state!(updated)
      submitted_params = params_for_submit(state.form_data, button)

      observed = %{
        action: :submit,
        clicked: button.text,
        path: updated_state.path,
        method: method,
        mode: updated_state.mode,
        params: submitted_params
      }

      cleared_state = %{updated_state | form_data: clear_submitted_form(state.form_data, button.form)}
      {:ok, update_session(updated, cleared_state, :submit, observed), observed}
    else
      observed = %{action: :submit, clicked: button.text, path: state.path, mode: state.mode}
      {:error, session, observed, "live driver static mode only supports GET form submissions"}
    end
  end

  defp build_submit_target(action, fallback_path, params) do
    base_path = action_path(action, fallback_path)
    query = URI.encode_query(params)

    if query == "" do
      base_path
    else
      uri = URI.parse(base_path)
      merged_query = merge_query(uri.query, query)
      URI.to_string(%{uri | query: merged_query})
    end
  end

  defp merge_query(nil, right), do: right
  defp merge_query("", right), do: right
  defp merge_query(left, right), do: left <> "&" <> right

  defp action_path(action, fallback_path) do
    action
    |> normalize_action(fallback_path)
    |> to_request_path(fallback_path)
  end

  defp normalize_action(value, _fallback_path) when is_binary(value) and value != "", do: value
  defp normalize_action(_value, fallback_path), do: fallback_path || "/"

  defp to_request_path(action, fallback_path) do
    uri = URI.parse(action)

    case {uri.scheme, String.starts_with?(action, "/")} do
      {scheme, _} when is_binary(scheme) ->
        URI.to_string(%URI{path: uri.path || "/", query: uri.query})

      {_, true} ->
        action

      _ ->
        base = URI.parse("http://cerberus.test" <> (fallback_path || "/"))
        merged = URI.merge(base, action)
        URI.to_string(%URI{path: merged.path || "/", query: merged.query})
    end
  end

  defp maybe_live_patch_path(nil, fallback_path), do: fallback_path

  defp maybe_live_patch_path(view, fallback_path) do
    case read_patch_path(view) do
      nil -> fallback_path
      path -> to_request_path(path, fallback_path)
    end
  end

  defp read_patch_path(view) do
    Phoenix.LiveViewTest.assert_patch(view, 0)
  rescue
    ArgumentError -> nil
  end

  defp empty_form_data do
    %{active_form: nil, values: %{}}
  end

  defp put_form_value(form_data, form, name, value) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
    form_values = Map.get(values, key, %{})
    next_values = Map.put(values, key, Map.put(form_values, name, value))
    %{active_form: key, values: next_values}
  end

  defp params_for_submit(form_data, button) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(button.form, active_form)
    params = Map.get(values, key, %{})

    case button_payload(button) do
      nil -> params
      {name, value} -> Map.put(params, name, value)
    end
  end

  defp clear_submitted_form(form_data, form) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
    %{active_form: nil, values: Map.delete(values, key)}
  end

  defp normalize_form_data(%{active_form: _active_form, values: values} = data) when is_map(values),
    do: data

  defp normalize_form_data(values) when is_map(values) do
    %{active_form: "__default__", values: %{"__default__" => values}}
  end

  defp normalize_form_data(_), do: empty_form_data()

  defp form_key(form, _active_form) when is_binary(form) and form != "", do: "form:" <> form
  defp form_key(_form, active_form) when is_binary(active_form), do: active_form
  defp form_key(_form, _active_form), do: "__default__"

  defp button_payload(button) do
    case {button.button_name, button.button_value} do
      {name, value} when is_binary(name) and name != "" -> {name, value || ""}
      _ -> nil
    end
  end
end
