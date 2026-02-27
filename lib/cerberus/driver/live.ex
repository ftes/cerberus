defmodule Cerberus.Driver.Live do
  @moduledoc "Live driver adapter backed by a real Phoenix endpoint via LiveViewTest."

  @behaviour Cerberus.Driver

  import Phoenix.LiveViewTest, only: [element: 2, element: 3, render: 1, render_click: 1]

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Html
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.Query
  alias Cerberus.Session

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          mode: :static | :live,
          view: term() | nil,
          html: String.t(),
          form_data: map(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            mode: :static,
            view: nil,
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
    from_driver = session.mode
    from_path = session.current_path

    case try_live(conn) do
      {:ok, view, html} ->
        transition = transition(from_driver, :live, :visit, from_path, current_path)

        %{
          session
          | conn: conn,
            mode: :live,
            view: view,
            html: html,
            current_path: current_path,
            last_result: %{op: :visit, observed: %{path: current_path, mode: :live, transition: transition}}
        }

      :error ->
        html = conn.resp_body || ""
        transition = transition(from_driver, :static, :visit, from_path, current_path)

        %StaticSession{
          endpoint: session.endpoint,
          conn: conn,
          html: html,
          form_data: session.form_data,
          current_path: current_path,
          last_result: %{op: :visit, observed: %{path: current_path, mode: :static, transition: transition}}
        }
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    session = with_latest_html(session)
    kind = Keyword.get(opts, :kind, :any)

    case find_clickable_link(session, expected, opts, kind) do
      {:ok, link} when is_binary(link.href) ->
        updated = visit(session, link.href, [])

        transition =
          transition(
            session.mode,
            Session.driver_kind(updated),
            :click,
            session.current_path,
            Session.current_path(updated)
          )

        observed = %{
          action: :link,
          path: Session.current_path(updated),
          mode: Session.driver_kind(updated),
          clicked: link.text,
          texts: Html.texts(updated.html, :any),
          transition: transition
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      :error ->
        case find_clickable_button(session, expected, opts, kind) do
          {:ok, button} when session.mode == :live and session.view != nil ->
            click_live_button(session, button)

          {:ok, button} ->
            observed = %{
              action: :button,
              clicked: button.text,
              path: session.current_path,
              mode: session.mode,
              transition: Session.transition(session)
            }

            {:error, session, observed, click_button_error(kind)}

          :error ->
            observed = %{
              action: :click,
              path: session.current_path,
              mode: session.mode,
              texts: Html.texts(session.html, :any),
              transition: Session.transition(session)
            }

            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, value, opts) do
    session = with_latest_html(session)

    case session.mode do
      :live ->
        observed = %{
          action: :fill_in,
          path: session.current_path,
          mode: session.mode,
          transition: Session.transition(session)
        }

        {:error, session, observed, "live driver does not yet support fill_in on live routes"}

      :static ->
        case Html.find_form_field(session.html, expected, opts) do
          {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
            updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: session.mode,
              field: field,
              value: value,
              transition: Session.transition(session)
            }

            {:ok, update_session(updated, :fill_in, observed), observed}

          {:ok, _field} ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: session.mode,
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: session.mode,
              transition: Session.transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    session = with_latest_html(session)

    case session.mode do
      :live ->
        observed = %{
          action: :submit,
          path: session.current_path,
          mode: session.mode,
          transition: Session.transition(session)
        }

        {:error, session, observed, "live driver does not yet support submit on live routes"}

      :static ->
        case Html.find_submit_button(session.html, expected, opts) do
          {:ok, button} ->
            do_submit(session, button)

          :error ->
            observed = %{
              action: :submit,
              path: session.current_path,
              mode: session.mode,
              transition: Session.transition(session)
            }

            {:error, session, observed, "no submit button matched locator"}
        end
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    session = with_latest_html(session)
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(session.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: session.current_path,
      mode: session.mode,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected,
      transition: Session.transition(session)
    }

    if matched == [] do
      {:error, session, observed, "expected text not found"}
    else
      {:ok, update_session(session, :assert_has, observed), observed}
    end
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected}, opts) do
    session = with_latest_html(session)
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(session.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: session.current_path,
      mode: session.mode,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected,
      transition: Session.transition(session)
    }

    if matched == [] do
      {:ok, update_session(session, :refute_has, observed), observed}
    else
      {:error, session, observed, "unexpected matching text found"}
    end
  end

  defp click_live_button(session, button) do
    result =
      session.view
      |> live_button_element(button)
      |> render_click()

    case result do
      rendered when is_binary(rendered) ->
        path = maybe_live_patch_path(session.view, session.current_path)
        updated = %{session | html: rendered, current_path: path}
        transition = transition(session.mode, :live, :click, session.current_path, path)

        observed = %{
          action: :button,
          clicked: button.text,
          path: path,
          mode: :live,
          texts: Html.texts(rendered, :any),
          transition: transition
        }

        {:ok, update_session(updated, :click, observed), observed}

      {:error, {:live_redirect, %{to: to}}} ->
        redirected_result(session, button, to, :live_redirect)

      {:error, {:redirect, %{to: to}}} ->
        redirected_result(session, button, to, :redirect)

      {:error, {:live_patch, %{to: to}}} ->
        rendered = render(session.view)
        updated = %{session | html: rendered, current_path: to}
        transition = transition(session.mode, :live, :live_patch, session.current_path, to)

        observed = %{
          action: :button,
          clicked: button.text,
          path: to,
          mode: :live,
          texts: Html.texts(rendered, :any),
          transition: transition
        }

        {:ok, update_session(updated, :click, observed), observed}

      other ->
        observed = %{
          action: :button,
          clicked: button.text,
          path: session.current_path,
          mode: session.mode,
          result: other,
          transition: Session.transition(session)
        }

        {:error, session, observed, "unexpected live click result"}
    end
  end

  defp live_button_element(view, %{selector: selector}) when is_binary(selector) and selector != "" do
    element(view, selector)
  end

  defp live_button_element(view, button) do
    element(view, "button", button.text)
  end

  defp redirected_result(session, button, to, reason) do
    updated = visit(session, to, [])

    transition =
      transition(session.mode, Session.driver_kind(updated), reason, session.current_path, Session.current_path(updated))

    observed = %{
      action: :button,
      clicked: button.text,
      path: Session.current_path(updated),
      mode: Session.driver_kind(updated),
      texts: Html.texts(updated.html, :any),
      transition: transition
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

  defp with_latest_html(%__MODULE__{mode: :live, view: view} = session) when not is_nil(view) do
    %{session | html: render(view)}
  end

  defp with_latest_html(session), do: session

  defp update_session(%__MODULE__{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp update_last_result(%__MODULE__{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp update_last_result(%StaticSession{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp find_clickable_link(_session, _expected, _opts, :button), do: :error

  defp find_clickable_link(session, expected, opts, _kind), do: Html.find_link(session.html, expected, opts)

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(session, expected, opts, _kind), do: Html.find_button(session.html, expected, opts)

  defp click_button_error(:button), do: "live driver can only click buttons on live routes for click_button"
  defp click_button_error(_kind), do: "live driver can only click buttons on live routes"

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

      transition =
        transition(
          session.mode,
          Session.driver_kind(updated),
          :submit,
          session.current_path,
          Session.current_path(updated)
        )

      observed = %{
        action: :submit,
        clicked: button.text,
        path: Session.current_path(updated),
        method: method,
        mode: Session.driver_kind(updated),
        params: submitted_params,
        transition: transition
      }

      cleared_form_data = clear_submitted_form(session.form_data, button.form)
      {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}
    else
      observed = %{
        action: :submit,
        clicked: button.text,
        path: session.current_path,
        mode: session.mode,
        transition: Session.transition(session)
      }

      {:error, session, observed, "live driver static mode only supports GET form submissions"}
    end
  end

  defp clear_submitted_session(%__MODULE__{} = session, form_data, op, observed) do
    %{session | form_data: form_data, last_result: %{op: op, observed: observed}}
  end

  defp clear_submitted_session(%StaticSession{} = session, form_data, op, observed) do
    %{session | form_data: form_data, last_result: %{op: op, observed: observed}}
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
