defmodule Cerberus.Driver.Static do
  @moduledoc "Static driver adapter backed by a real Phoenix endpoint via ConnTest."

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Html
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Locator
  alias Cerberus.Query
  alias Cerberus.Session

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          html: String.t(),
          form_data: map(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            html: "",
            form_data: %{active_form: nil, values: %{}},
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    %__MODULE__{
      endpoint: Conn.endpoint!(opts)
    }
  end

  @impl true
  def visit(%__MODULE__{} = session, path, _opts) do
    conn = Conn.ensure_conn(session.conn)
    conn = Conn.follow_get(session.endpoint, conn, path)
    current_path = Conn.current_path(conn, path)

    case try_live(conn) do
      {:ok, view, html} ->
        %LiveSession{
          endpoint: session.endpoint,
          conn: conn,
          mode: :live,
          view: view,
          html: html,
          form_data: session.form_data,
          current_path: current_path,
          last_result: %{op: :visit, observed: %{path: current_path, mode: :live}}
        }

      :error ->
        html = conn.resp_body || ""

        %{
          session
          | conn: conn,
            html: html,
            current_path: current_path,
            last_result: %{op: :visit, observed: %{path: current_path, mode: :static}}
        }
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    kind = Keyword.get(opts, :kind, :any)

    case find_clickable_link(session, expected, opts, kind) do
      {:ok, link} when is_binary(link.href) ->
        updated = visit(session, link.href, [])

        observed = %{
          action: :link,
          path: Session.current_path(updated),
          mode: Session.driver_kind(updated),
          clicked: link.text,
          texts: Html.texts(updated.html, :any)
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      :error ->
        case find_clickable_button(session, expected, opts, kind) do
          {:ok, button} ->
            observed = %{action: :button, clicked: button.text, path: session.current_path}
            {:error, session, observed, click_button_error(kind)}

          :error ->
            observed = %{action: :click, path: session.current_path, texts: Html.texts(session.html, :any)}
            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, value, opts) do
    case Html.find_form_field(session.html, expected, opts) do
      {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: :fill_in,
          path: session.current_path,
          field: field,
          value: value
        }

        {:ok, update_session(updated, :fill_in, observed), observed}

      {:ok, _field} ->
        observed = %{action: :fill_in, path: session.current_path}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: :fill_in, path: session.current_path}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    case Html.find_submit_button(session.html, expected, opts) do
      {:ok, button} ->
        do_submit(session, button)

      :error ->
        observed = %{action: :submit, path: session.current_path}
        {:error, session, observed, "no submit button matched locator"}
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(session.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: session.current_path,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:error, session, observed, "expected text not found"}
    else
      {:ok, update_last_result(session, :assert_has, observed), observed}
    end
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(session.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: session.current_path,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:ok, update_last_result(session, :refute_has, observed), observed}
    else
      {:error, session, observed, "unexpected matching text found"}
    end
  end

  defp update_session(session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp update_last_result(%__MODULE__{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp update_last_result(%LiveSession{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp find_clickable_link(_session, _expected, _opts, :button), do: :error

  defp find_clickable_link(session, expected, opts, _kind), do: Html.find_link(session.html, expected, opts)

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(session, expected, opts, _kind), do: Html.find_button(session.html, expected, opts)

  defp click_button_error(:button), do: "static driver does not support button clicks"
  defp click_button_error(_kind), do: "static driver does not support dynamic button clicks"

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp do_submit(session, button) do
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
        |> build_submit_target(session.current_path, params_for_submit(session.form_data, button))

      updated = visit(session, target, [])
      submitted_params = params_for_submit(session.form_data, button)

      observed = %{
        action: :submit,
        clicked: button.text,
        method: method,
        path: Session.current_path(updated),
        mode: Session.driver_kind(updated),
        params: submitted_params
      }

      cleared_form_data = clear_submitted_form(session.form_data, button.form)
      {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}
    else
      observed = %{action: :submit, clicked: button.text, path: session.current_path, method: method}
      {:error, session, observed, "static driver only supports GET form submissions"}
    end
  end

  defp clear_submitted_session(%__MODULE__{} = session, form_data, op, observed) do
    %{
      session
      | form_data: form_data,
        last_result: %{op: op, observed: observed}
    }
  end

  defp clear_submitted_session(%LiveSession{} = session, form_data, op, observed) do
    %{
      session
      | form_data: form_data,
        last_result: %{op: op, observed: observed}
    }
  end

  defp try_live(conn) do
    case Phoenix.LiveViewTest.__live__(conn, nil, []) do
      {:ok, view, html} -> {:ok, view, html}
      _ -> :error
    end
  rescue
    _ -> :error
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

  defp normalize_form_data(%{active_form: _active_form, values: values} = data) when is_map(values), do: data

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
