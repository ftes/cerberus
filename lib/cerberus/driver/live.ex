defmodule Cerberus.Driver.Live do
  @moduledoc false

  @behaviour Cerberus.Driver

  import Phoenix.LiveViewTest, only: [element: 2, element: 3, render: 1, render_click: 1]

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Html
  alias Cerberus.LiveViewHtml
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Query
  alias Cerberus.Session
  alias Cerberus.UploadFile
  alias Phoenix.LiveViewTest.TreeDOM

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          assert_timeout_ms: non_neg_integer(),
          view: term() | nil,
          html: String.t(),
          form_data: map(),
          scope: String.t() | nil,
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            assert_timeout_ms: 0,
            view: nil,
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
      assert_timeout_ms: Session.assert_timeout_from_opts!(opts, Session.live_browser_assert_timeout_default_ms())
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
    from_driver = route_kind(session)
    from_path = session.current_path

    case try_live(conn) do
      {:ok, view, html} ->
        transition = transition(from_driver, :live, :visit, from_path, current_path)

        %{
          session
          | conn: conn,
            view: view,
            html: html,
            scope: session.scope,
            current_path: current_path,
            last_result: %{op: :visit, observed: %{path: current_path, mode: :live, transition: transition}}
        }

      :error ->
        html = conn.resp_body || ""
        transition = transition(from_driver, :static, :visit, from_path, current_path)

        %StaticSession{
          endpoint: session.endpoint,
          conn: conn,
          assert_timeout_ms: session.assert_timeout_ms,
          html: html,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: %{op: :visit, observed: %{path: current_path, mode: :static, transition: transition}}
        }
    end
  end

  @doc false
  @spec follow_redirect(Session.t(), String.t()) :: Session.t()
  def follow_redirect(%__MODULE__{} = session, to) when is_binary(to) do
    visit(session, to, [])
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)
    kind = Keyword.get(opts, :kind, :any)

    case find_clickable_link(session, expected, match_opts, kind) do
      {:ok, link} when is_binary(link.href) ->
        if live_route?(session) do
          click_live_link(session, link)
        else
          click_link_via_visit(session, link, :click)
        end

      :error ->
        case find_clickable_button(session, expected, match_opts, kind) do
          {:ok, button} ->
            click_or_error_for_button(session, button, kind)

          :error ->
            observed = %{
              action: :click,
              path: session.current_path,
              mode: route_kind(session),
              texts: Html.texts(session.html, :any, Session.scope(session)),
              transition: Session.transition(session)
            }

            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, value, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_fill_in(session, expected, value, match_opts)

      :static ->
        case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
            updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: route_kind(session),
              field: field,
              value: value,
              transition: Session.transition(session)
            }

            {:ok, update_session(updated, :fill_in, observed), observed}

          {:ok, _field} ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def select(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)
    option = Keyword.fetch!(opts, :option)

    case route_kind(session) do
      :live ->
        do_live_select(session, expected, option, match_opts)

      :static ->
        select_in_static_mode(session, expected, option, match_opts)
    end
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_choose(session, expected, match_opts)

      :static ->
        choose_in_static_mode(session, expected, match_opts)
    end
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_toggle_checkbox(session, expected, match_opts, true, :check)

      :static ->
        case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
            value = toggled_checkbox_value(session, field, true)
            updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

            observed = %{
              action: :check,
              path: session.current_path,
              mode: route_kind(session),
              field: field,
              checked: true,
              transition: Session.transition(session)
            }

            {:ok, update_session(updated, :check, observed), observed}

          {:ok, %{name: name}} when is_binary(name) and name != "" ->
            observed = %{
              action: :check,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched field is not a checkbox"}

          {:ok, _field} ->
            observed = %{
              action: :check,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :check,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_toggle_checkbox(session, expected, match_opts, false, :uncheck)

      :static ->
        case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
            value = toggled_checkbox_value(session, field, false)
            updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

            observed = %{
              action: :uncheck,
              path: session.current_path,
              mode: route_kind(session),
              field: field,
              checked: false,
              transition: Session.transition(session)
            }

            {:ok, update_session(updated, :uncheck, observed), observed}

          {:ok, %{name: name}} when is_binary(name) and name != "" ->
            observed = %{
              action: :uncheck,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched field is not a checkbox"}

          {:ok, _field} ->
            observed = %{
              action: :uncheck,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :uncheck,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, path, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)

    case route_kind(session) do
      :live ->
        case LiveViewHtml.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
            do_live_upload(session, field, path)

          {:ok, _field} ->
            observed = %{
              action: :upload,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "matched upload field does not include a name attribute"}

          :error ->
            observed = %{
              action: :upload,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "no file input matched locator"}
        end

      :static ->
        upload_in_static_mode(session, expected, path, match_opts)
    end
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)

    case route_kind(session) do
      :live ->
        case LiveViewHtml.find_submit_button(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, button} ->
            do_live_submit(session, button)

          :error ->
            observed = %{
              action: :submit,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "no submit button matched locator"}
        end

      :static ->
        case Html.find_submit_button(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, button} ->
            do_submit(session, button)

          :error ->
            observed = %{
              action: :submit,
              path: session.current_path,
              mode: route_kind(session),
              transition: Session.transition(session)
            }

            {:error, session, observed, "no submit button matched locator"}
        end
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    visible = Keyword.get(opts, :visible, true)
    {session, texts} = assertion_texts(session, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, match_opts))

    observed = %{
      path: session.current_path,
      mode: route_kind(session),
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
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    match_opts = locator_match_opts(locator, opts)
    visible = Keyword.get(opts, :visible, true)
    {session, texts} = assertion_texts(session, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, match_opts))

    observed = %{
      path: session.current_path,
      mode: route_kind(session),
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

  defp click_live_button(session, %{dispatch_change: true} = button) do
    click_live_dispatch_change_button(session, button)
  end

  defp click_live_button(session, button) do
    result =
      session.view
      |> live_button_element(button, Session.scope(session))
      |> render_click()

    case result do
      rendered when is_binary(rendered) ->
        click_live_button_rendered(session, button, rendered, :click)

      {:error, {:live_redirect, %{to: to}}} ->
        redirected_result(session, button, to, :live_redirect)

      {:error, {:redirect, %{to: to}}} ->
        redirected_result(session, button, to, :redirect)

      {:error, {:live_patch, %{to: to}}} ->
        rendered = render(session.view)
        path = to_request_path(to, session.current_path)
        click_live_button_rendered(session, button, rendered, :live_patch, path)

      other ->
        observed = %{
          action: :button,
          clicked: button.text,
          path: session.current_path,
          mode: route_kind(session),
          result: other,
          transition: Session.transition(session)
        }

        {:error, session, observed, "unexpected live click result"}
    end
  end

  defp click_live_dispatch_change_button(session, button) do
    form_selector = button[:form_selector]

    if is_binary(form_selector) and form_selector != "" do
      target = dispatch_change_target(button)
      payload = dispatch_change_payload(session, button, form_selector)
      additional = dispatch_change_additional_payload(button, target)

      result =
        session.view
        |> Phoenix.LiveViewTest.form(form_selector, payload)
        |> Phoenix.LiveViewTest.render_change(additional)

      case resolve_live_change_result(session, result, target || []) do
        {:ok, changed_session, change} ->
          observed = %{
            action: :button,
            clicked: button.text,
            path: Session.current_path(changed_session),
            mode: Session.driver_kind(changed_session),
            phx_change: change.triggered,
            target: change.target,
            texts: Html.texts(changed_session.html, :any, Session.scope(changed_session)),
            transition: change.transition
          }

          {:ok, update_last_result(changed_session, :click, observed), observed}

        {:error, failed_session, reason, details} ->
          click_live_button_error(session, button, failed_session, reason, details)
      end
    else
      observed = %{
        action: :button,
        clicked: button.text,
        path: session.current_path,
        mode: route_kind(session),
        transition: Session.transition(session)
      }

      {:error, session, observed, "dispatch(change) requires a resolvable form selector"}
    end
  end

  defp dispatch_change_payload(session, button, form_selector) do
    defaults = Html.form_defaults(session.html, form_selector, Session.scope(session))
    active = pruned_params_for_form(session, button.form, form_selector)

    defaults
    |> Map.merge(active)
    |> decode_query_params()
  end

  defp dispatch_change_target(button) do
    case button_payload(button) do
      {name, _value} -> target_path(name)
      nil -> nil
    end
  end

  defp dispatch_change_additional_payload(button, target) do
    additional = button_payload_map(button)

    case target do
      nil -> additional
      _ -> Map.put(additional, "_target", target)
    end
  end

  defp click_live_button_rendered(session, button, rendered, reason, path_override \\ nil) do
    case apply_live_rendered_result(session, rendered, reason, path_override) do
      {:ok, updated, transition} ->
        observed = %{
          action: :button,
          clicked: button.text,
          path: Session.current_path(updated),
          mode: Session.driver_kind(updated),
          texts: Html.texts(updated.html, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      {:error, failed_session, reason, details} ->
        click_live_button_error(session, button, failed_session, reason, details)
    end
  end

  defp click_live_button_error(session, button, failed_session, reason, details) do
    observed = %{
      action: :button,
      clicked: button.text,
      path: session.current_path,
      mode: route_kind(session),
      details: details,
      transition: Session.transition(session)
    }

    {:error, failed_session, observed, reason}
  end

  defp click_live_link(session, link) do
    result = maybe_render_click_link(session, link)

    case result do
      rendered when is_binary(rendered) ->
        path = maybe_live_patch_path(session.view, session.current_path)
        updated = %{session | html: rendered, current_path: path}
        transition = transition(route_kind(session), :live, :click, session.current_path, path)

        observed = %{
          action: :link,
          clicked: link.text,
          path: path,
          mode: :live,
          texts: Html.texts(rendered, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_session(updated, :click, observed), observed}

      {:error, {:live_redirect, %{to: to}}} ->
        redirected_result(session, link, to, :live_redirect, :link)

      {:error, {:redirect, %{to: to}}} ->
        redirected_result(session, link, to, :redirect, :link)

      {:error, {:live_patch, %{to: to}}} ->
        rendered = render(session.view)
        path = to_request_path(to, session.current_path)
        updated = %{session | html: rendered, current_path: path}
        transition = transition(route_kind(session), :live, :live_patch, session.current_path, path)

        observed = %{
          action: :link,
          clicked: link.text,
          path: path,
          mode: :live,
          texts: Html.texts(rendered, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_session(updated, :click, observed), observed}

      {:error, :live_click_unsupported} ->
        click_link_via_visit(session, link, :click)

      _other ->
        click_link_via_visit(session, link, :click)
    end
  end

  defp click_link_via_visit(session, link, reason) do
    updated = visit(session, link.href, [])

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: :link,
      path: Session.current_path(updated),
      mode: Session.driver_kind(updated),
      clicked: link.text,
      texts: Html.texts(updated.html, :any, Session.scope(updated)),
      transition: transition
    }

    {:ok, update_last_result(updated, :click, observed), observed}
  end

  defp maybe_render_click_link(session, link) do
    session.view
    |> live_link_element(link, Session.scope(session))
    |> render_click()
  rescue
    _ -> {:error, :live_click_unsupported}
  end

  defp live_button_element(view, %{selector: selector}, scope) when is_binary(selector) and selector != "" do
    element(view, scoped_selector(selector, scope))
  end

  defp live_button_element(view, button, scope) do
    element(view, scoped_selector("button", scope), button.text)
  end

  defp live_link_element(view, %{selector: selector}, scope) when is_binary(selector) and selector != "" do
    element(view, scoped_selector(selector, scope))
  end

  defp live_link_element(view, link, scope) do
    element(view, scoped_selector("a", scope), link.text)
  end

  defp redirected_result(session, clicked, to, reason, action \\ :button) do
    updated = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: action,
      clicked: clicked.text,
      path: Session.current_path(updated),
      mode: Session.driver_kind(updated),
      texts: Html.texts(updated.html, :any, Session.scope(updated)),
      transition: transition
    }

    {:ok, update_last_result(updated, :click, observed), observed}
  end

  defp scoped_selector(selector, scope) when is_binary(scope) and scope != "", do: "#{scope} #{selector}"
  defp scoped_selector(selector, _scope), do: selector

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

  defp with_latest_html(%__MODULE__{view: view} = session) when not is_nil(view) do
    %{session | html: render(view)}
  end

  defp with_latest_html(session), do: session

  defp assertion_texts(%__MODULE__{} = session, visibility) do
    case live_texts_from_tree(session, visibility) do
      {:ok, texts} ->
        {session, texts}

      :error ->
        session = with_latest_html(session)
        {session, Html.texts(session.html, visibility, Session.scope(session))}
    end
  end

  defp live_texts_from_tree(%__MODULE__{view: view} = session, visibility) when not is_nil(view) do
    with {:ok, html_tree} <- live_html_tree(view) do
      view_tree = TreeDOM.by_id!(html_tree, view.id)

      {visible, hidden} =
        view_tree
        |> scoped_live_tree_nodes(Session.scope(session))
        |> Enum.reduce({[], []}, fn root, acc ->
          collect_live_texts(List.wrap(root), false, acc)
        end)

      visible = Enum.uniq(visible)
      hidden = Enum.uniq(hidden)

      texts =
        case visibility do
          true -> visible
          false -> hidden
          :any -> visible ++ hidden
        end

      {:ok, texts}
    end
  rescue
    _ -> :error
  end

  defp live_texts_from_tree(_session, _visibility), do: :error

  defp live_html_tree(%{proxy: {_ref, _topic, proxy_pid}}) when is_pid(proxy_pid) do
    case GenServer.call(proxy_pid, :html, :infinity) do
      {:ok, {html_tree, _static_path}} -> {:ok, html_tree}
      _ -> :error
    end
  catch
    :exit, _ -> :error
  end

  defp live_html_tree(_view), do: :error

  defp scoped_live_tree_nodes(view_tree, nil), do: [view_tree]
  defp scoped_live_tree_nodes(view_tree, ""), do: [view_tree]

  defp scoped_live_tree_nodes(view_tree, scope) when is_binary(scope) do
    view_tree
    |> List.wrap()
    |> LazyHTML.from_tree()
    |> safe_query(scope)
    |> Enum.flat_map(&LazyHTML.to_tree/1)
  end

  defp collect_live_texts(nodes, hidden_parent?, acc) when is_list(nodes) do
    Enum.reduce(nodes, acc, fn node, acc ->
      case node do
        text when is_binary(text) ->
          append_live_text(text, hidden_parent?, acc)

        {"script", _attrs, _children} ->
          acc

        {"style", _attrs, _children} ->
          acc

        {_tag, attrs, children} when is_list(attrs) and is_list(children) ->
          hidden? = hidden_parent? or hidden_live_element?(attrs)
          collect_live_texts(children, hidden?, acc)

        _ ->
          acc
      end
    end)
  end

  defp append_live_text(text, hidden?, {visible, hidden}) do
    text =
      text
      |> String.replace("\u00A0", " ")
      |> String.trim()

    cond do
      text == "" ->
        {visible, hidden}

      hidden? ->
        {visible, hidden ++ [text]}

      true ->
        {visible ++ [text], hidden}
    end
  end

  defp hidden_live_element?(attrs) do
    hidden_attr? = Enum.any?(attrs, fn {name, _} -> to_string(name) == "hidden" end)

    style =
      attrs
      |> Enum.find_value("", fn {name, value} ->
        if to_string(name) == "style", do: String.downcase(to_string(value)), else: false
      end)
      |> String.replace(" ", "")

    hidden_attr? or String.contains?(style, "display:none") or
      String.contains?(style, "visibility:hidden")
  end

  defp safe_query(node, selector) do
    LazyHTML.query(node, selector)
  rescue
    _ -> []
  end

  defp snapshot_html(%__MODULE__{view: view}) when not is_nil(view), do: render(view)
  defp snapshot_html(%__MODULE__{html: html}) when is_binary(html), do: html

  defp endpoint_url(endpoint) when is_atom(endpoint) do
    endpoint.url()
  rescue
    _ -> nil
  end

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

  defp find_clickable_link(session, expected, opts, _kind) do
    Html.find_link(session.html, expected, opts, Session.scope(session))
  end

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(%{view: view} = session, expected, opts, _kind) when not is_nil(view) do
    LiveViewHtml.find_live_clickable_button(session.html, expected, opts, Session.scope(session))
  end

  defp find_clickable_button(%__MODULE__{} = session, expected, opts, _kind) do
    Html.find_button(session.html, expected, opts, Session.scope(session))
  end

  defp click_button_error(:button), do: "live driver can only click buttons on live routes for click_button"
  defp click_button_error(_kind), do: "live driver can only click buttons on live routes"

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp click_or_error_for_button(session, button, kind) do
    if live_route?(session) do
      click_live_button(session, button)
    else
      observed = %{
        action: :button,
        clicked: button.text,
        path: session.current_path,
        mode: route_kind(session),
        transition: Session.transition(session)
      }

      {:error, session, observed, click_button_error(kind)}
    end
  end

  defp do_live_upload(session, field, path) do
    file = UploadFile.read!(path)
    live_upload_name = live_upload_name!(field.name)
    form_selector = upload_form_selector(field, Session.scope(session))

    entry = %{
      last_modified: file.last_modified_unix_ms,
      name: file.file_name,
      content: file.content,
      size: file.size,
      type: file.mime_type
    }

    builder = fn ->
      Phoenix.ChannelTest.__connect__(session.endpoint, Phoenix.LiveView.Socket, %{}, [])
    end

    upload_progress_result =
      session.view
      |> Phoenix.LiveViewTest.__file_input__(form_selector, live_upload_name, [entry], builder)
      |> Phoenix.LiveViewTest.render_upload(file.file_name)
      |> maybe_raise_upload_error!(session, file.file_name, live_upload_name)

    change_result =
      case upload_progress_result do
        {:error, _} = error -> error
        _ -> maybe_upload_change_result(session, form_selector, field)
      end

    result = upload_change_result(change_result, upload_progress_result)
    finalize_upload_result(result, session, field, file.file_name)
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{
        action: :upload,
        path: session.current_path,
        mode: route_kind(session),
        field: field,
        transition: Session.transition(session)
      }

      {:error, session, observed, Exception.message(error)}
  end

  defp upload_change_result(_change_result, {:error, _} = upload_progress_result) do
    upload_progress_result
  end

  defp upload_change_result(change_result, _upload_progress_result), do: change_result

  defp finalize_upload_result(result, session, field, file_name) do
    case result do
      rendered when is_binary(rendered) ->
        path = maybe_live_patch_path(session.view, session.current_path)
        updated = %{session | html: rendered, current_path: path}
        transition = transition(route_kind(session), :live, :upload, session.current_path, path)

        observed = %{
          action: :upload,
          path: path,
          mode: :live,
          field: field,
          file_name: file_name,
          texts: Html.texts(rendered, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_session(updated, :upload, observed), observed}

      {:error, {:live_redirect, %{to: to}}} ->
        upload_redirect_result(session, field, file_name, to, :live_redirect)

      {:error, {:redirect, %{to: to}}} ->
        upload_redirect_result(session, field, file_name, to, :redirect)

      {:error, {:live_patch, %{to: to}}} ->
        rendered = render(session.view)
        path = to_request_path(to, session.current_path)
        updated = %{session | html: rendered, current_path: path}
        transition = transition(route_kind(session), :live, :live_patch, session.current_path, path)

        observed = %{
          action: :upload,
          path: path,
          mode: :live,
          field: field,
          file_name: file_name,
          texts: Html.texts(rendered, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_session(updated, :upload, observed), observed}

      other ->
        observed = %{
          action: :upload,
          path: session.current_path,
          mode: route_kind(session),
          field: field,
          file_name: file_name,
          result: other,
          transition: Session.transition(session)
        }

        {:error, session, observed, "unexpected live upload result"}
    end
  end

  defp upload_redirect_result(session, field, file_name, to, reason) do
    updated = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: :upload,
      path: Session.current_path(updated),
      mode: Session.driver_kind(updated),
      field: field,
      file_name: file_name,
      texts: Html.texts(updated.html, :any, Session.scope(updated)),
      transition: transition
    }

    {:ok, update_last_result(updated, :upload, observed), observed}
  end

  defp maybe_raise_upload_error!({:error, [[_ref, error]]}, session, file_name, live_upload_name) do
    case error do
      :not_accepted -> raise ArgumentError, message: not_accepted_error_msg(session, file_name, live_upload_name)
      :too_many_files -> raise ArgumentError, message: too_many_files_error_msg(session, file_name, live_upload_name)
      :too_large -> raise ArgumentError, message: too_large_error_msg(session, file_name, live_upload_name)
      _ -> raise ArgumentError, message: "upload failed with #{inspect(error)}"
    end
  end

  defp maybe_raise_upload_error!(upload_result, _session, _file_name, _live_upload_name), do: upload_result

  defp upload_form_selector(%{form: form}, _scope) when is_binary(form) and form != "" do
    "#" <> form
  end

  defp upload_form_selector(%{form_selector: form_selector}, _scope)
       when is_binary(form_selector) and form_selector != "" do
    form_selector
  end

  defp upload_form_selector(_field, scope) when is_binary(scope) and scope != "", do: scope
  defp upload_form_selector(_field, _scope), do: "form"

  defp maybe_upload_change_result(session, form_selector, %{input_phx_change: true, name: name}) do
    session.view
    |> Phoenix.LiveViewTest.form(form_selector)
    |> Phoenix.LiveViewTest.render_change(%{"_target" => name})
  end

  defp maybe_upload_change_result(session, form_selector, %{form_phx_change: true, name: name}) do
    session.view
    |> Phoenix.LiveViewTest.form(form_selector)
    |> Phoenix.LiveViewTest.render_change(%{"_target" => name})
  end

  defp maybe_upload_change_result(session, _form_selector, _field), do: render(session.view)

  defp live_upload_name!(name) when is_binary(name) and name != "" do
    String.to_existing_atom(name)
  end

  defp live_upload_name!(_name) do
    raise ArgumentError, "matched upload field does not include a valid name"
  end

  defp not_accepted_error_msg(session, file_name, live_upload_name) do
    allowed_list =
      session
      |> upload_config(live_upload_name)
      |> Map.get(:acceptable_exts, MapSet.new())
      |> MapSet.to_list()
      |> Enum.join(", ")

    """
    Unsupported file type.

    You were trying to upload "#{file_name}",
    but the only file types specified in allow_upload are [#{allowed_list}].
    """
  end

  defp too_many_files_error_msg(session, file_name, live_upload_name) do
    upload = upload_config(session, live_upload_name)
    name = Map.get(upload, :name, live_upload_name)
    max_entries = Map.get(upload, :max_entries, 0)

    """
    Too many files uploaded.

    While attempting to upload "#{file_name}", you've exceeded #{max_entries} file(s). If this is intentional,
    consider updating allow_upload(:#{name}, max_entries: #{max_entries}).
    """
  end

  defp too_large_error_msg(session, file_name, live_upload_name) do
    upload = upload_config(session, live_upload_name)
    name = Map.get(upload, :name, live_upload_name)
    max_file_size = Map.get(upload, :max_file_size, 0)

    """
    File too large.

    While attempting to upload "#{file_name}", you've exceeded the maximum file size of #{max_file_size} bytes. If this is intentional,
    consider updating allow_upload(:#{name}, max_file_size: #{max_file_size}).
    """
  end

  defp upload_config(%{conn: %Plug.Conn{assigns: assigns}}, live_upload_name) do
    assigns |> Map.get(:uploads, %{}) |> Map.get(live_upload_name, %{})
  end

  defp upload_config(_session, _live_upload_name), do: %{}

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
      form_selector = submit_form_selector(button)
      submitted_params = params_for_submit(session, button, form_selector)

      target =
        button
        |> Map.get(:action)
        |> build_submit_target(session.current_path, submitted_params)

      updated = visit(session, target, [])

      transition =
        transition(
          route_kind(session),
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
        mode: route_kind(session),
        transition: Session.transition(session)
      }

      {:error, session, observed, "live driver static mode only supports GET form submissions"}
    end
  end

  defp do_live_submit(session, button) do
    form_payload = submit_form_payload(session, button)
    additional = button_payload_map(button)

    if button[:form_phx_submit] do
      do_live_phx_submit(session, button, form_payload, additional)
    else
      params = Map.merge(form_payload, additional)
      do_live_action_submit(session, button, params)
    end
  end

  defp do_live_phx_submit(session, button, form_payload, additional) do
    form_selector = submit_form_selector(button)

    if is_binary(form_selector) and form_selector != "" do
      result =
        session.view
        |> Phoenix.LiveViewTest.form(form_selector, form_payload)
        |> Phoenix.LiveViewTest.render_submit(additional)

      resolve_live_submit_result(session, result, button, Map.merge(form_payload, additional))
    else
      observed = %{
        action: :submit,
        clicked: button.text,
        path: session.current_path,
        mode: route_kind(session),
        transition: Session.transition(session)
      }

      {:error, session, observed, "live submit requires a resolvable form selector"}
    end
  end

  defp do_live_action_submit(session, button, params) do
    method = normalize_submit_method(button.method)
    result = follow_form_request(session, method, button.action, params)

    case result do
      {:ok, updated, transition} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: Session.current_path(updated),
          method: method,
          mode: Session.driver_kind(updated),
          params: params,
          transition: transition
        }

        cleared_form_data = clear_submitted_form(session.form_data, button.form)
        {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: session.current_path,
          mode: route_kind(session),
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp resolve_live_submit_result(session, rendered, button, submitted_params) when is_binary(rendered) do
    case apply_live_rendered_result(session, rendered, :submit) do
      {:ok, updated, transition} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: Session.current_path(updated),
          method: normalize_submit_method(button.method),
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
          path: session.current_path,
          mode: route_kind(session),
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp resolve_live_submit_result(session, {:error, {:live_redirect, %{to: to}}}, button, submitted_params) do
    submitted_redirect_result(session, button, to, submitted_params, :live_redirect)
  end

  defp resolve_live_submit_result(session, {:error, {:redirect, %{to: to}}}, button, submitted_params) do
    submitted_redirect_result(session, button, to, submitted_params, :redirect)
  end

  defp resolve_live_submit_result(session, {:error, {:live_patch, %{to: to}}}, button, submitted_params) do
    rendered = render(session.view)
    path = to_request_path(to, session.current_path)

    case apply_live_rendered_result(session, rendered, :live_patch, path) do
      {:ok, updated, transition} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: Session.current_path(updated),
          method: normalize_submit_method(button.method),
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
          path: session.current_path,
          mode: route_kind(session),
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp resolve_live_submit_result(session, other, _button, _submitted_params) do
    observed = %{
      action: :submit,
      path: session.current_path,
      mode: route_kind(session),
      result: other,
      transition: Session.transition(session)
    }

    {:error, session, observed, "unexpected live submit result"}
  end

  defp submitted_redirect_result(session, button, to, submitted_params, reason) do
    updated = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: :submit,
      clicked: button.text,
      path: Session.current_path(updated),
      method: normalize_submit_method(button.method),
      mode: Session.driver_kind(updated),
      params: submitted_params,
      transition: transition
    }

    cleared_form_data = clear_submitted_form(session.form_data, button.form)
    {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}
  end

  defp select_in_static_mode(session, expected, option, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "select"} = field} when is_binary(name) and name != "" ->
        case Html.select_values(session.html, field, option, opts, Session.scope(session)) do
          {:ok, %{values: values, multiple?: multiple?}} ->
            value = select_value_for_update(session, field, option, values, multiple?, :static)
            updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

            observed = %{
              action: :select,
              path: session.current_path,
              mode: route_kind(session),
              field: field,
              option: option,
              value: value,
              transition: Session.transition(session)
            }

            {:ok, update_session(updated, :select, observed), observed}

          {:error, reason} ->
            observed = %{
              action: :select,
              path: session.current_path,
              mode: route_kind(session),
              field: field,
              option: option,
              transition: Session.transition(session)
            }

            {:error, session, observed, reason}
        end

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{
          action: :select,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched field is not a select element"}

      {:ok, _field} ->
        observed = %{
          action: :select,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{
          action: :select,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp choose_in_static_mode(session, expected, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "radio"} = field} when is_binary(name) and name != "" ->
        value = field[:input_value] || "on"
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: :choose,
          path: session.current_path,
          mode: route_kind(session),
          field: field,
          value: value,
          transition: Session.transition(session)
        }

        {:ok, update_session(updated, :choose, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{
          action: :choose,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched field is not a radio input"}

      {:ok, _field} ->
        observed = %{
          action: :choose,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{
          action: :choose,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp upload_in_static_mode(session, expected, path, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "file"} = field} when is_binary(name) and name != "" ->
        file = UploadFile.read!(path)
        value = upload_value_for_update(session, field, file, path, :static)
        updated = %{session | form_data: put_form_value(session.form_data, field.form, name, value)}

        observed = %{
          action: :upload,
          path: session.current_path,
          mode: route_kind(session),
          field: field,
          file_name: file.file_name,
          transition: Session.transition(session)
        }

        {:ok, update_session(updated, :upload, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{
          action: :upload,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched field is not a file input"}

      {:ok, _field} ->
        observed = %{
          action: :upload,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched upload field does not include a name attribute"}

      :error ->
        observed = %{
          action: :upload,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "no file input matched locator"}
    end
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{
        action: :upload,
        path: session.current_path,
        mode: route_kind(session),
        transition: Session.transition(session)
      }

      {:error, session, observed, Exception.message(error)}
  end

  defp do_live_select(session, expected, option, opts) do
    with {:ok, field} <- find_live_select_field(session, expected, opts),
         {:ok, %{values: values, multiple?: multiple?}} <-
           Html.select_values(session.html, field, option, opts, Session.scope(session)) do
      value = select_value_for_update(session, field, option, values, multiple?, :live)
      form_data = put_form_value(session.form_data, field.form, field.name, value)
      updated = %{session | form_data: form_data}
      handle_live_select_change(session, updated, field, option, value)
    else
      {:error, reason} ->
        live_select_error(session, option, reason)
    end
  end

  defp do_live_choose(session, expected, opts) do
    case find_live_radio_field(session, expected, opts) do
      {:ok, field} ->
        value = field[:input_value] || "on"
        form_data = put_form_value(session.form_data, field.form, field.name, value)
        updated = %{session | form_data: form_data}
        handle_live_choose_change(session, updated, field, value)

      {:error, reason} ->
        live_choose_error(session, reason)
    end
  end

  defp find_live_select_field(session, expected, opts) do
    case LiveViewHtml.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "select"} = field} when is_binary(name) and name != "" ->
        {:ok, field}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        {:error, "matched field is not a select element"}

      {:ok, _field} ->
        {:error, "matched field does not include a name attribute"}

      :error ->
        {:error, "no form field matched locator"}
    end
  end

  defp find_live_radio_field(session, expected, opts) do
    case LiveViewHtml.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "radio"} = field} when is_binary(name) and name != "" ->
        {:ok, field}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        {:error, "matched field is not a radio input"}

      {:ok, _field} ->
        {:error, "matched field does not include a name attribute"}

      :error ->
        {:error, "no form field matched locator"}
    end
  end

  defp handle_live_select_change(session, updated, field, option, value) do
    case maybe_trigger_live_change(updated, field) do
      {:ok, changed_session, change} ->
        observed = %{
          action: :select,
          path: Session.current_path(changed_session),
          mode: Session.driver_kind(changed_session),
          field: field,
          option: option,
          value: value,
          phx_change: change.triggered,
          target: change.target,
          transition: change.transition || Session.transition(changed_session)
        }

        {:ok, update_last_result(changed_session, :select, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :select,
          path: session.current_path,
          mode: route_kind(session),
          field: field,
          option: option,
          value: value,
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp handle_live_choose_change(session, updated, field, value) do
    case maybe_trigger_live_change(updated, field) do
      {:ok, changed_session, change} ->
        observed = %{
          action: :choose,
          path: Session.current_path(changed_session),
          mode: Session.driver_kind(changed_session),
          field: field,
          value: value,
          phx_change: change.triggered,
          target: change.target,
          transition: change.transition || Session.transition(changed_session)
        }

        {:ok, update_last_result(changed_session, :choose, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :choose,
          path: session.current_path,
          mode: route_kind(session),
          field: field,
          value: value,
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp live_select_error(session, option, reason) do
    observed = %{
      action: :select,
      path: session.current_path,
      mode: route_kind(session),
      option: option,
      transition: Session.transition(session)
    }

    {:error, session, observed, reason}
  end

  defp live_choose_error(session, reason) do
    observed = %{
      action: :choose,
      path: session.current_path,
      mode: route_kind(session),
      transition: Session.transition(session)
    }

    {:error, session, observed, reason}
  end

  defp do_live_fill_in(session, expected, value, opts) do
    case LiveViewHtml.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
        form_data = put_form_value(session.form_data, field.form, name, value)
        updated = %{session | form_data: form_data}

        case maybe_trigger_live_change(updated, field) do
          {:ok, changed_session, change} ->
            observed = %{
              action: :fill_in,
              path: Session.current_path(changed_session),
              mode: Session.driver_kind(changed_session),
              field: field,
              value: value,
              phx_change: change.triggered,
              target: change.target,
              transition: change.transition || Session.transition(changed_session)
            }

            {:ok, update_last_result(changed_session, :fill_in, observed), observed}

          {:error, failed_session, reason, details} ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              mode: route_kind(session),
              field: field,
              value: value,
              details: details,
              transition: Session.transition(session)
            }

            {:error, failed_session, observed, reason}
        end

      {:ok, _field} ->
        observed = %{
          action: :fill_in,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{
          action: :fill_in,
          path: session.current_path,
          mode: route_kind(session),
          transition: Session.transition(session)
        }

        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp do_live_toggle_checkbox(session, expected, opts, checked?, op) do
    case find_checkbox_field(session, expected, opts) do
      {:ok, field} ->
        apply_live_checkbox_change(session, field, checked?, op)

      {:error, reason} ->
        observed = checkbox_error_observed(session, op)
        {:error, session, observed, reason}
    end
  end

  defp find_checkbox_field(session, expected, opts) do
    case LiveViewHtml.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
        {:ok, field}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        {:error, "matched field is not a checkbox"}

      {:ok, _field} ->
        {:error, "matched field does not include a name attribute"}

      :error ->
        {:error, "no form field matched locator"}
    end
  end

  defp apply_live_checkbox_change(session, field, checked?, op) do
    value = toggled_checkbox_value(session, field, checked?)
    form_data = put_form_value(session.form_data, field.form, field.name, value)
    updated = %{session | form_data: form_data}

    case maybe_trigger_live_change(updated, field) do
      {:ok, changed_session, change} ->
        observed = %{
          action: op,
          path: Session.current_path(changed_session),
          mode: Session.driver_kind(changed_session),
          field: field,
          checked: checked?,
          phx_change: change.triggered,
          target: change.target,
          transition: change.transition || Session.transition(changed_session)
        }

        {:ok, update_last_result(changed_session, op, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: op,
          path: session.current_path,
          mode: route_kind(session),
          field: field,
          checked: checked?,
          details: details,
          transition: Session.transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp checkbox_error_observed(session, op) do
    %{
      action: op,
      path: session.current_path,
      mode: route_kind(session),
      transition: Session.transition(session)
    }
  end

  defp clear_submitted_session(%__MODULE__{} = session, form_data, op, observed) do
    %{session | form_data: form_data, last_result: %{op: op, observed: observed}}
  end

  defp clear_submitted_session(%StaticSession{} = session, form_data, op, observed) do
    %{session | form_data: form_data, last_result: %{op: op, observed: observed}}
  end

  defp maybe_trigger_live_change(%__MODULE__{} = session, field) do
    cond do
      field[:input_phx_change] ->
        trigger_input_phx_change(session, field)

      field[:form_phx_change] ->
        trigger_form_phx_change(session, field)

      true ->
        {:ok, session, %{triggered: false, target: nil, transition: Session.transition(session)}}
    end
  end

  defp trigger_input_phx_change(session, field) do
    target = target_path(field.name)
    selector = field[:selector]

    if is_binary(selector) and selector != "" do
      payload =
        session
        |> form_payload_for_change(field)
        |> Map.take([field.name])
        |> Map.put("_target", target)

      result =
        session.view
        |> element(scoped_selector(selector, Session.scope(session)))
        |> Phoenix.LiveViewTest.render_change(payload)

      resolve_live_change_result(session, result, target)
    else
      {:error, session, "live field change requires a resolvable field selector", %{field: field}}
    end
  end

  defp trigger_form_phx_change(session, field) do
    target = target_path(field.name)
    form_selector = field[:form_selector]

    if is_binary(form_selector) and form_selector != "" do
      payload = form_payload_for_change(session, field)
      additional = %{"_target" => target}

      result =
        session.view
        |> Phoenix.LiveViewTest.form(form_selector, payload)
        |> Phoenix.LiveViewTest.render_change(additional)

      resolve_live_change_result(session, result, target)
    else
      {:error, session, "form-level phx-change requires a resolvable form selector", %{field: field}}
    end
  end

  defp resolve_live_change_result(session, rendered, target) when is_binary(rendered) do
    case apply_live_rendered_result(session, rendered, :fill_in) do
      {:ok, updated, transition} ->
        {:ok, updated, %{triggered: true, target: target, transition: transition}}

      {:error, failed_session, reason, details} ->
        {:error, failed_session, reason, details}
    end
  end

  defp resolve_live_change_result(session, {:error, {:live_redirect, %{to: to}}}, target) do
    redirected = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(redirected),
        :live_redirect,
        session.current_path,
        Session.current_path(redirected)
      )

    {:ok, redirected, %{triggered: true, target: target, transition: transition}}
  end

  defp resolve_live_change_result(session, {:error, {:redirect, %{to: to}}}, target) do
    redirected = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(redirected),
        :redirect,
        session.current_path,
        Session.current_path(redirected)
      )

    {:ok, redirected, %{triggered: true, target: target, transition: transition}}
  end

  defp resolve_live_change_result(session, {:error, {:live_patch, %{to: to}}}, target) do
    rendered = render(session.view)
    path = to_request_path(to, session.current_path)

    case apply_live_rendered_result(session, rendered, :live_patch, path) do
      {:ok, updated, transition} ->
        {:ok, updated, %{triggered: true, target: target, transition: transition}}

      {:error, failed_session, reason, details} ->
        {:error, failed_session, reason, details}
    end
  end

  defp resolve_live_change_result(session, other, _target) do
    {:error, session, "unexpected live change result", %{result: other}}
  end

  defp apply_live_rendered_result(session, rendered, reason, path_override \\ nil) do
    case maybe_follow_trigger_action(session, rendered) do
      :no_trigger ->
        path = path_override || maybe_live_patch_path(session.view, session.current_path)
        updated = %{session | html: rendered, current_path: path}
        transition = transition(route_kind(session), :live, reason, session.current_path, path)
        {:ok, updated, transition}

      {:ok, updated} ->
        transition =
          transition(
            route_kind(session),
            Session.driver_kind(updated),
            reason,
            session.current_path,
            Session.current_path(updated)
          )

        {:ok, updated, transition}

      {:error, reason, details} ->
        {:error, session, reason, details}
    end
  end

  defp maybe_follow_trigger_action(session, rendered) do
    case LiveViewHtml.trigger_action_forms(rendered) do
      [] ->
        :no_trigger

      [form] ->
        trigger_action_submit(session, form)

      forms ->
        {:error, "Found multiple forms with phx-trigger-action.", %{forms: forms}}
    end
  end

  defp trigger_action_submit(session, form) do
    params = trigger_action_submit_payload(session, form)
    method = normalize_submit_method(form[:method])
    action = form[:action]

    case follow_form_request(session, method, action, params) do
      {:ok, updated, _transition} ->
        cleared_form_data = clear_submitted_form(session.form_data, form[:form])
        {:ok, %{updated | form_data: cleared_form_data}}

      {:error, _failed_session, reason, details} ->
        {:error, reason, details}
    end
  end

  defp trigger_action_submit_payload(session, form) do
    active = pruned_params_for_form(session, form[:form], form[:form_selector])
    defaults = Map.get(form, :defaults, %{})
    defaults |> Map.merge(active) |> decode_query_params()
  end

  defp follow_form_request(session, method, action, params) do
    method = normalize_submit_method(method)
    request_path = submit_request_path(method, action, session.current_path, params)
    request_params = if method == "get", do: %{}, else: params

    conn =
      session.conn
      |> Conn.ensure_conn()
      |> then(&Conn.follow_request(session.endpoint, &1, method, request_path, request_params))

    updated = session_from_conn(session, conn, request_path)

    transition =
      transition(
        route_kind(session),
        Session.driver_kind(updated),
        :submit,
        session.current_path,
        Session.current_path(updated)
      )

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
        %{
          session
          | conn: conn,
            view: view,
            html: html,
            current_path: current_path
        }

      :error ->
        %StaticSession{
          endpoint: session.endpoint,
          conn: conn,
          assert_timeout_ms: session.assert_timeout_ms,
          html: conn.resp_body || "",
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: session.last_result
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

  defp normalize_submit_method(value) when is_atom(value) do
    value |> to_string() |> normalize_submit_method()
  end

  defp normalize_submit_method(_), do: "get"

  defp submit_form_payload(session, button) do
    defaults = submit_form_defaults(session, button)
    form_selector = submit_form_selector(button)
    active = pruned_params_for_form(session, button.form, form_selector)
    defaults |> Map.merge(active) |> decode_query_params()
  end

  defp submit_form_defaults(session, button) do
    case submit_form_selector(button) do
      selector when is_binary(selector) and selector != "" ->
        Html.form_defaults(session.html, selector, Session.scope(session))

      _ ->
        %{}
    end
  end

  defp submit_form_selector(%{form_selector: selector}) when is_binary(selector) and selector != "", do: selector

  defp submit_form_selector(%{form: form}) when is_binary(form) and form != "" do
    ~s(form[id="#{form}"])
  end

  defp submit_form_selector(_), do: nil

  defp button_payload_map(button) do
    case button_payload(button) do
      nil -> %{}
      {name, value} -> %{name => value}
    end
  end

  defp form_payload_for_change(session, field) do
    defaults = form_defaults_for_change(session, field)
    active = pruned_active_form_values(session, field)

    defaults
    |> Map.merge(active)
    |> decode_query_params()
  end

  defp form_defaults_for_change(%__MODULE__{} = session, field) do
    case field[:form_selector] do
      selector when is_binary(selector) and selector != "" ->
        Html.form_defaults(session.html, selector, Session.scope(session))

      _ ->
        %{}
    end
  end

  defp active_form_values(form_data, field) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(field.form, active_form)
    Map.get(values, key, %{})
  end

  defp pruned_active_form_values(session, field) do
    active = active_form_values(session.form_data, field)
    keep = form_field_name_allowlist(session, field[:form_selector])
    prune_form_params(active, keep)
  end

  defp toggled_checkbox_value(session, field, checked?) do
    name = field.name
    defaults = form_defaults_for_change(session, field)
    active = pruned_active_form_values(session, field)
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

  defp select_value_for_update(_session, _field, _option, values, false, _route_kind) do
    List.first(values)
  end

  defp select_value_for_update(_session, _field, option, values, true, _route_kind) when is_list(option) do
    values
  end

  defp select_value_for_update(session, field, _option, values, true, _route_kind) do
    defaults = form_defaults_for_change(session, field)
    active = pruned_active_form_values(session, field)
    current = Map.get(active, field.name, Map.get(defaults, field.name))

    current
    |> checkbox_value_list()
    |> Enum.concat(values)
    |> Enum.uniq()
  end

  defp upload_value_for_update(session, field, file, source_path, _route_kind) do
    upload = %Plug.Upload{
      path: source_path,
      filename: file.file_name,
      content_type: file.mime_type
    }

    if String.ends_with?(field.name, "[]") do
      defaults = form_defaults_for_change(session, field)
      active = pruned_active_form_values(session, field)
      current = Map.get(active, field.name, Map.get(defaults, field.name))
      checkbox_value_list(current) ++ [upload]
    else
      upload
    end
  end

  defp checkbox_value_list(nil), do: []
  defp checkbox_value_list(value) when is_list(value), do: value
  defp checkbox_value_list(value), do: [value]

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

  defp decode_query_params(params) when is_map(params) do
    params
    |> expand_query_entries()
    |> Enum.map_join("&", fn {name, value} ->
      "#{URI.encode_www_form(name)}=#{URI.encode_www_form(to_string(value))}"
    end)
    |> Plug.Conn.Query.decode()
  end

  defp expand_query_entries(params) do
    Enum.flat_map(params, fn
      {name, value} when is_list(value) ->
        Enum.map(value, &{name, &1})

      {name, value} ->
        [{name, value}]
    end)
  end

  defp target_path(name) when is_binary(name) do
    name
    |> then(&"#{URI.encode_www_form(&1)}=cerberus")
    |> Plug.Conn.Query.decode()
    |> map_target_path()
  end

  defp map_target_path(map) when is_map(map) and map_size(map) == 1 do
    [{key, value}] = Map.to_list(map)
    [key | value_target_path(value)]
  end

  defp map_target_path(_), do: []

  defp value_target_path(value) when is_map(value) and map_size(value) == 1 do
    [{key, nested}] = Map.to_list(value)
    [key | value_target_path(nested)]
  end

  defp value_target_path(value) when is_list(value), do: []
  defp value_target_path(_), do: []

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

  defp params_for_submit(session, button, form_selector) do
    params =
      session
      |> submit_defaults_for_selector(form_selector)
      |> Map.merge(pruned_params_for_form(session, button.form, form_selector))

    case button_payload(button) do
      nil -> params
      {name, value} -> Map.put(params, name, value)
    end
  end

  defp submit_defaults_for_selector(_session, selector) when selector in [nil, ""], do: %{}

  defp submit_defaults_for_selector(session, selector) when is_binary(selector) do
    Html.form_defaults(session.html, selector, Session.scope(session))
  end

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

  defp form_field_name_allowlist(_session, selector) when selector in [nil, ""], do: nil

  defp form_field_name_allowlist(session, selector) do
    Html.form_field_names(session.html, selector, Session.scope(session))
  end

  defp prune_form_params(params, nil) when is_map(params), do: params
  defp prune_form_params(params, %MapSet{} = keep) when is_map(params), do: Map.take(params, MapSet.to_list(keep))

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

  defp live_route?(%__MODULE__{view: view}) when not is_nil(view), do: true
  defp live_route?(%__MODULE__{}), do: false

  defp route_kind(%__MODULE__{} = session) do
    if live_route?(session), do: :live, else: :static
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
