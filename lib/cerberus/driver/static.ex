defmodule Cerberus.Driver.Static do
  @moduledoc false

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Html
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
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
          assert_timeout_ms: session.assert_timeout_ms,
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
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

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
        value = upload_value_for_update(session, field, file, path)
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

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

    if matched == [] do
      {:error, session, observed, "expected text not found"}
    else
      {:ok, update_last_result(session, :assert_has, observed), observed}
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
    form_selector = submit_form_selector(button)
    submitted_params = params_for_submit(session, button, form_selector)

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

        cleared_form_data = clear_submitted_form(session.form_data, button.form)
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
          assert_timeout_ms: session.assert_timeout_ms,
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

  defp empty_form_data do
    %{active_form: nil, values: %{}}
  end

  defp toggle_checkbox(session, expected, opts, checked?, op) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
        value = toggled_checkbox_value(session, field, checked?)
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

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
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

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
            value = select_value_for_update(session, field, option, values, multiple?)
            updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

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

  defp put_form_value(form_data, form, name, value) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
    form_values = Map.get(values, key, %{})
    next_values = Map.put(values, key, Map.put(form_values, name, value))
    %{active_form: key, values: next_values}
  end

  defp params_for_submit(session, button, form_selector) do
    params = submit_form_payload(session, button, form_selector)

    case button_payload(button) do
      nil -> params
      {name, value} -> Map.put(params, name, value)
    end
  end

  defp submit_form_payload(session, button, form_selector) do
    defaults = submit_form_defaults(session, button, form_selector)
    active = pruned_params_for_form(session, button.form, form_selector)
    Map.merge(defaults, active)
  end

  defp submit_form_defaults(_session, _button, selector) when selector in [nil, ""], do: %{}

  defp submit_form_defaults(session, _button, selector) when is_binary(selector) do
    Html.form_defaults(session.html, selector, Session.scope(session))
  end

  defp submit_form_selector(%{form_selector: selector}) when is_binary(selector) and selector != "", do: selector

  defp submit_form_selector(%{form: form}) when is_binary(form) and form != "" do
    ~s(form[id="#{form}"])
  end

  defp submit_form_selector(_), do: nil

  defp pruned_params_for_form(session, form, form_selector) do
    active = params_for_form(session.form_data, form)
    keep = form_field_name_allowlist(session, form_selector)
    prune_form_params(active, keep)
  end

  defp params_for_form(form_data, form) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
    Map.get(values, key, %{})
  end

  defp toggled_checkbox_value(session, field, checked?) do
    name = field.name
    defaults = submit_defaults_for_field(session, field)
    active = pruned_params_for_form(session, field.form, field[:form_selector])
    current = Map.get(active, name, Map.get(defaults, name))
    input_value = field[:input_value] || "on"

    if String.ends_with?(name, "[]") do
      current_list = checkbox_value_list(current)

      if checked? do
        ensure_checkbox_value(current_list, input_value)
      else
        Enum.reject(current_list, &(&1 == input_value))
      end
    else
      if checked? do
        input_value
      else
        checkbox_unchecked_value(defaults, name, input_value)
      end
    end
  end

  defp submit_defaults_for_field(session, field) do
    case field[:form_selector] do
      selector when is_binary(selector) and selector != "" ->
        Html.form_defaults(session.html, selector, Session.scope(session))

      _ ->
        %{}
    end
  end

  defp checkbox_value_list(nil), do: []
  defp checkbox_value_list(value) when is_list(value), do: value
  defp checkbox_value_list(value), do: [value]

  defp select_value_for_update(_session, _field, _option, values, false) do
    List.first(values)
  end

  defp select_value_for_update(_session, _field, option, values, true) when is_list(option) do
    values
  end

  defp select_value_for_update(session, field, _option, values, true) do
    defaults = submit_defaults_for_field(session, field)
    active = pruned_params_for_form(session, field.form, field[:form_selector])
    current = Map.get(active, field.name, Map.get(defaults, field.name))

    current
    |> checkbox_value_list()
    |> Enum.concat(values)
    |> Enum.uniq()
  end

  defp ensure_checkbox_value(values, input_value) do
    if Enum.any?(values, &(&1 == input_value)) do
      values
    else
      values ++ [input_value]
    end
  end

  defp checkbox_unchecked_value(defaults, name, input_value) do
    case Map.get(defaults, name) do
      ^input_value -> ""
      nil -> ""
      other -> other
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

  defp upload_value_for_update(session, field, file, source_path) do
    upload = %Plug.Upload{
      path: source_path,
      filename: file.file_name,
      content_type: file.mime_type
    }

    if String.ends_with?(field.name, "[]") do
      defaults = submit_defaults_for_field(session, field)
      active = pruned_params_for_form(session, field.form, field[:form_selector])
      current = Map.get(active, field.name, Map.get(defaults, field.name))
      checkbox_value_list(current) ++ [upload]
    else
      upload
    end
  end

  defp form_key(form, _active_form) when is_binary(form) and form != "", do: "form:" <> form
  defp form_key(_form, active_form) when is_binary(active_form), do: active_form
  defp form_key(_form, _active_form), do: "__default__"

  defp button_payload(button) do
    case {button.button_name, button.button_value} do
      {name, value} when is_binary(name) and name != "" -> {name, value || ""}
      _ -> nil
    end
  end

  defp form_field_name_allowlist(_session, selector) when selector in [nil, ""], do: nil

  defp form_field_name_allowlist(session, selector) do
    Html.form_field_names(session.html, selector, Session.scope(session))
  end

  defp prune_form_params(params, nil) when is_map(params), do: params
  defp prune_form_params(params, %MapSet{} = keep) when is_map(params), do: Map.take(params, MapSet.to_list(keep))

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
