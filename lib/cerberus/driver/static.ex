defmodule Cerberus.Driver.Static do
  @moduledoc false

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static.FormData
  alias Cerberus.Html
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Phoenix.Conn
  alias Cerberus.Query
  alias Cerberus.Session
  alias Cerberus.UploadFile

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          assert_timeout_ms: non_neg_integer(),
          html: String.t(),
          form_data: map(),
          scope: String.t() | nil,
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            assert_timeout_ms: 0,
            html: "",
            form_data: %{active_form: nil, values: %{}},
            scope: nil,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    %__MODULE__{
      endpoint: Conn.endpoint!(opts),
      conn: initial_conn(opts),
      assert_timeout_ms: Session.assert_timeout_from_opts!(opts)
    }
  end

  @spec open_user(t()) :: t()
  def open_user(%__MODULE__{} = session) do
    new_session(
      endpoint: session.endpoint,
      conn: Conn.fork_user_conn(session.conn),
      assert_timeout_ms: session.assert_timeout_ms
    )
  end

  @spec open_tab(t()) :: t()
  def open_tab(%__MODULE__{} = session) do
    new_session(
      endpoint: session.endpoint,
      conn: Conn.fork_tab_conn(session.conn),
      assert_timeout_ms: session.assert_timeout_ms
    )
  end

  @spec switch_tab(t(), Session.t()) :: Session.t()
  def switch_tab(%__MODULE__{}, target_session), do: target_session

  @spec close_tab(t()) :: t()
  def close_tab(%__MODULE__{} = session), do: session

  @impl true
  def open_browser(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
    html = snapshot_html(session)
    path = OpenBrowser.write_snapshot!(html, endpoint_url(session.endpoint))
    _ = open_fun.(path)
    session
  end

  @impl true
  def visit(%__MODULE__{} = session, path, _opts) do
    conn = Conn.ensure_conn(session.conn)
    conn = Conn.follow_get(session.endpoint, conn, path)
    current_path = Conn.current_path(conn, path)
    from_path = session.current_path

    case try_live(conn) do
      {:ok, view, html} ->
        transition = transition(:static, :live, :visit, from_path, current_path)

        %LiveSession{
          endpoint: session.endpoint,
          conn: conn,
          assert_timeout_ms: assert_timeout_for_live(session),
          view: view,
          html: html,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: %{op: :visit, observed: %{path: current_path, mode: :live, transition: transition}}
        }

      :error ->
        html = conn.resp_body || ""
        transition = transition(:static, :static, :visit, from_path, current_path)

        %{
          session
          | conn: conn,
            html: html,
            current_path: current_path,
            last_result: %{op: :visit, observed: %{path: current_path, mode: :static, transition: transition}}
        }
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    kind = Keyword.get(opts, :kind, :any)

    case find_clickable_link(session, expected, match_opts, kind) do
      {:ok, link} when is_binary(link.href) ->
        updated = visit(session, link.href, [])

        transition =
          transition(:static, Session.driver_kind(updated), :click, session.current_path, Session.current_path(updated))

        observed = %{
          action: :link,
          path: Session.current_path(updated),
          mode: Session.driver_kind(updated),
          clicked: link.text,
          texts: Html.texts(updated.html, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      :error ->
        case find_clickable_button(session, expected, match_opts, kind) do
          {:ok, button} ->
            observed = %{
              action: :button,
              clicked: button.text,
              path: session.current_path,
              transition: Session.transition(session)
            }

            {:error, session, observed, click_button_error(kind)}

          :error ->
            observed = %{
              action: :click,
              path: session.current_path,
              texts: Html.texts(session.html, :any, Session.scope(session)),
              transition: Session.transition(session)
            }

            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, value, opts) do
    match_opts = locator_match_opts(locator, opts)

    case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
      {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
        updated = %{session | form_data: FormData.put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: :fill_in,
          path: session.current_path,
          field: field,
          value: value,
          transition: Session.transition(session)
        }

        {:ok, update_session(updated, :fill_in, observed), observed}

      {:ok, _field} ->
        observed = %{action: :fill_in, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: :fill_in, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  @impl true
  def select(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    option = Keyword.fetch!(opts, :option)
    select_field(session, expected, match_opts, option, :select)
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    choose_radio(session, expected, match_opts)
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    toggle_checkbox(session, expected, match_opts, true, :check)
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    toggle_checkbox(session, expected, match_opts, false, :uncheck)
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, path, opts) do
    match_opts = locator_match_opts(locator, opts)

    case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "file"} = field} when is_binary(name) and name != "" ->
        file = UploadFile.read!(path)
        value = FormData.upload_value_for_update(session, field, file, path)
        updated = %{session | form_data: FormData.put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: :upload,
          path: session.current_path,
          field: field,
          file_name: file.file_name,
          transition: Session.transition(session)
        }

        {:ok, update_session(updated, :upload, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{action: :upload, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field is not a file input"}

      {:ok, _field} ->
        observed = %{action: :upload, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched upload field does not include a name attribute"}

      :error ->
        observed = %{action: :upload, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "no file input matched locator"}
    end
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{action: :upload, path: session.current_path, transition: Session.transition(session)}
      {:error, session, observed, Exception.message(error)}
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)

    case Html.find_submit_button(session.html, expected, match_opts, Session.scope(session)) do
      {:ok, button} ->
        do_submit(session, button)

      :error ->
        observed = %{action: :submit, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "no submit button matched locator"}
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    visible = Keyword.get(opts, :visible, true)
    match_by = Keyword.get(match_opts, :match_by, :text)
    texts = Html.assertion_values(session.html, match_by, visible, Session.scope(session))
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, match_opts))

    observed = %{
      path: session.current_path,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected,
      transition: Session.transition(session)
    }

    case Query.assertion_count_outcome(length(matched), match_opts, :assert) do
      :ok ->
        {:ok, update_last_result(session, :assert_has, observed), observed}

      {:error, reason} ->
        {:error, session, observed, reason}
    end
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    visible = Keyword.get(opts, :visible, true)
    match_by = Keyword.get(match_opts, :match_by, :text)
    texts = Html.assertion_values(session.html, match_by, visible, Session.scope(session))
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, match_opts))

    observed = %{
      path: session.current_path,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected,
      transition: Session.transition(session)
    }

    case Query.assertion_count_outcome(length(matched), match_opts, :refute) do
      :ok ->
        {:ok, update_last_result(session, :refute_has, observed), observed}

      {:error, reason} ->
        {:error, session, observed, reason}
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

  defp find_clickable_link(session, expected, opts, _kind) do
    Html.find_link(session.html, expected, opts, Session.scope(session))
  end

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(session, expected, opts, _kind) do
    Html.find_button(session.html, expected, opts, Session.scope(session))
  end

  defp click_button_error(:button), do: "static driver does not support button clicks"
  defp click_button_error(_kind), do: "static driver does not support dynamic button clicks"

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp do_submit(session, button) do
    method = normalize_submit_method(button.method)
    form_selector = FormData.submit_form_selector(button)
    submitted_params = FormData.params_for_submit(session, button, form_selector)

    case follow_form_request(session, method, button.action, submitted_params) do
      {:ok, updated, transition} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          method: method,
          path: Session.current_path(updated),
          mode: Session.driver_kind(updated),
          params: submitted_params,
          transition: transition
        }

        cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form)
        {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          method: method,
          path: session.current_path,
          mode: :static,
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp follow_form_request(session, method, action, params) do
    request_path = submit_request_path(method, action, session.current_path, params)
    request_params = if method == "get", do: %{}, else: params

    conn =
      session.conn
      |> Conn.ensure_conn()
      |> then(&Conn.follow_request(session.endpoint, &1, method, request_path, request_params))

    updated = session_from_conn(session, conn, request_path)

    transition =
      transition(:static, Session.driver_kind(updated), :submit, session.current_path, Session.current_path(updated))

    {:ok, updated, transition}
  rescue
    error ->
      {:error, session, Exception.message(error), %{method: method, action: action, params: params}}
  end

  defp submit_request_path("get", action, fallback_path, params) do
    build_submit_target(action, fallback_path, params)
  end

  defp submit_request_path(_method, action, fallback_path, _params) do
    action_path(action, fallback_path)
  end

  defp session_from_conn(session, conn, fallback_path) do
    current_path = Conn.current_path(conn, fallback_path)

    case try_live(conn) do
      {:ok, view, html} ->
        %LiveSession{
          endpoint: session.endpoint,
          conn: conn,
          assert_timeout_ms: assert_timeout_for_live(session),
          view: view,
          html: html,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: session.last_result
        }

      :error ->
        %{
          session
          | conn: conn,
            html: conn.resp_body || "",
            current_path: current_path
        }
    end
  end

  defp normalize_submit_method(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> "get"
      "post" -> "post"
      "put" -> "put"
      "patch" -> "patch"
      "delete" -> "delete"
      _ -> "get"
    end
  end

  defp normalize_submit_method(nil), do: "get"

  defp assert_timeout_for_live(session) do
    static_default = Session.default_assert_timeout_ms()

    if session.assert_timeout_ms == static_default do
      Session.live_browser_assert_timeout_default_ms()
    else
      session.assert_timeout_ms
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

  defp initial_conn(opts) do
    case Keyword.get(opts, :conn) do
      nil ->
        nil

      %Plug.Conn{} = conn ->
        conn

      other ->
        raise ArgumentError, "expected :conn option to be a Plug.Conn, got: #{inspect(other)}"
    end
  end

  defp snapshot_html(%__MODULE__{html: html}) when is_binary(html) and html != "", do: html
  defp snapshot_html(%__MODULE__{conn: %{resp_body: html}}) when is_binary(html), do: html
  defp snapshot_html(%__MODULE__{}), do: ""

  defp endpoint_url(endpoint) when is_atom(endpoint) do
    endpoint.url()
  rescue
    _ -> nil
  end

  defp build_submit_target(action, fallback_path, params) do
    base_path = action_path(action, fallback_path)
    query = encode_query_params(params)

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
        path_with_query(uri.path || "/", uri.query)

      {_, true} ->
        action

      _ ->
        base = URI.parse("http://cerberus.test" <> (fallback_path || "/"))
        merged = URI.merge(base, action)
        path_with_query(merged.path || "/", merged.query)
    end
  end

  defp path_with_query(path, nil), do: path
  defp path_with_query(path, ""), do: path
  defp path_with_query(path, query), do: path <> "?" <> query

  defp encode_query_params(params) when is_map(params) do
    if Enum.any?(params, fn {_name, value} -> is_list(value) end) do
      params
      |> Enum.flat_map(fn
        {name, values} when is_list(values) ->
          Enum.map(values, &{name, &1})

        {name, value} ->
          [{name, value}]
      end)
      |> Enum.map_join("&", fn {name, value} ->
        encoded_name = URI.encode_www_form(to_string(name))
        encoded_value = value |> normalize_query_value() |> URI.encode_www_form()
        encoded_name <> "=" <> encoded_value
      end)
    else
      URI.encode_query(params)
    end
  end

  defp normalize_query_value(nil), do: ""
  defp normalize_query_value(value), do: to_string(value)

  defp toggle_checkbox(session, expected, opts, checked?, op) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
        value = FormData.toggled_checkbox_value(session, field, checked?)
        updated = %{session | form_data: FormData.put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: op,
          path: session.current_path,
          field: field,
          checked: checked?,
          transition: Session.transition(session)
        }

        {:ok, update_session(updated, op, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{action: op, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field is not a checkbox"}

      {:ok, _field} ->
        observed = %{action: op, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: op, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp choose_radio(session, expected, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "radio"} = field} when is_binary(name) and name != "" ->
        value = field[:input_value] || "on"
        updated = %{session | form_data: FormData.put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: :choose,
          path: session.current_path,
          field: field,
          value: value,
          transition: Session.transition(session)
        }

        {:ok, update_session(updated, :choose, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{action: :choose, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field is not a radio input"}

      {:ok, _field} ->
        observed = %{action: :choose, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: :choose, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp select_field(session, expected, opts, option, op) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "select"} = field} when is_binary(name) and name != "" ->
        case Html.select_values(session.html, field, option, opts, Session.scope(session)) do
          {:ok, %{values: values, multiple?: multiple?}} ->
            value = FormData.select_value_for_update(session, field, option, values, multiple?)
            updated = %{session | form_data: FormData.put_form_value(session.form_data, field.form, name, value)}

            observed = %{
              action: op,
              path: session.current_path,
              field: field,
              option: option,
              value: value,
              transition: Session.transition(session)
            }

            {:ok, update_session(updated, op, observed), observed}

          {:error, reason} ->
            observed = %{
              action: op,
              path: session.current_path,
              field: field,
              option: option,
              transition: Session.transition(session)
            }

            {:error, session, observed, reason}
        end

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{action: op, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field is not a select element"}

      {:ok, _field} ->
        observed = %{action: op, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: op, path: session.current_path, transition: Session.transition(session)}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp transition(from_driver, to_driver, reason, from_path, to_path) do
    %{
      from_driver: from_driver,
      to_driver: to_driver,
      reason: reason,
      from_path: from_path,
      to_path: to_path
    }
  end
end
