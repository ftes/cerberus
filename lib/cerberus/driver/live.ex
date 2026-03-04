defmodule Cerberus.Driver.Live do
  @moduledoc false

  @behaviour Cerberus.Driver

  import Phoenix.LiveViewTest, only: [element: 2, render: 1, render_click: 1]

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.DownloadAssertion
  alias Cerberus.Driver.Live.FormData
  alias Cerberus.Driver.LocatorOps
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Html
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Phoenix.Conn
  alias Cerberus.Phoenix.LiveViewHTML
  alias Cerberus.Phoenix.LiveViewTimeout
  alias Cerberus.Query
  alias Cerberus.Session
  alias Cerberus.Session.Config, as: SessionConfig
  alias Cerberus.Session.LastResult
  alias Cerberus.UploadFile
  alias ExUnit.AssertionError
  alias Phoenix.LiveViewTest.TreeDOM
  alias Phoenix.LiveViewTest.View

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          assert_timeout_ms: non_neg_integer(),
          view: term() | nil,
          html: String.t(),
          form_data: map(),
          scope: Session.scope_value(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            assert_timeout_ms: 0,
            view: nil,
            html: "",
            form_data: %{active_form: nil, active_form_selector: nil, values: %{}},
            scope: nil,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    %__MODULE__{
      endpoint: Conn.endpoint!(opts),
      conn: initial_conn(opts),
      assert_timeout_ms:
        SessionConfig.assert_timeout_from_opts!(opts, SessionConfig.live_browser_assert_timeout_default_ms())
    }
  end

  @impl true
  @spec open_tab(t()) :: t()
  def open_tab(%__MODULE__{} = session) do
    new_session(
      endpoint: session.endpoint,
      conn: Conn.fork_tab_conn(session.conn),
      assert_timeout_ms: session.assert_timeout_ms
    )
  end

  @impl true
  @spec switch_tab(t(), Session.t()) :: Session.t()
  def switch_tab(%__MODULE__{} = session, %StaticSession{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    target_session
  end

  def switch_tab(%__MODULE__{} = session, %__MODULE__{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    target_session
  end

  def switch_tab(%__MODULE__{}, %BrowserSession{}) do
    raise ArgumentError, "cannot switch non-browser tab to a browser session"
  end

  @impl true
  @spec close_tab(t()) :: t()
  def close_tab(%__MODULE__{} = session), do: session

  @impl true
  def open_browser(%__MODULE__{view: view} = session, open_fun) when is_function(open_fun, 1) and not is_nil(view) do
    _ = Phoenix.LiveViewTest.open_browser(view, open_fun)
    session
  end

  def open_browser(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
    html = snapshot_html(session)
    path = OpenBrowser.write_snapshot!(html, endpoint_url(session.endpoint), session.endpoint)
    _ = open_fun.(path)
    session
  end

  @impl true
  def render_html(%__MODULE__{} = session, callback) when is_function(callback, 1) do
    html = snapshot_html(session)
    _ = callback.(LazyHTML.from_document(html))
    session
  end

  @impl true
  def unwrap(%__MODULE__{view: nil}, _fun) do
    raise ArgumentError, "unwrap/2 requires an active LiveView; visit a live route first"
  end

  @impl true
  def unwrap(%__MODULE__{} = session, fun) when is_function(fun, 1) do
    session.view
    |> fun.()
    |> unwrap_live_result(session)
  end

  @impl true
  def within(%__MODULE__{} = session, %Locator{} = locator, callback) when is_function(callback, 1) do
    previous_scope = Session.scope(session)
    resolved_scope = resolve_within_scope!(session, locator, previous_scope)
    live_child_scope = live_child_scope_candidate(locator, previous_scope, resolved_scope)

    case live_child_view_for_scope(session, live_child_scope) do
      {:ok, child_view} ->
        child_session =
          session
          |> Map.put(:view, child_view)
          |> Map.put(:html, Phoenix.LiveViewTest.render(child_view))
          |> Session.with_scope(nil)

        callback_result = callback.(child_session)
        restore_live_child_scope!(callback_result, session, previous_scope)

      :error ->
        scoped_session = Session.with_scope(session, resolved_scope)
        callback_result = callback.(scoped_session)
        restore_scope!(callback_result, previous_scope)
    end
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
            last_result: LastResult.new(:visit, %{path: current_path, transition: transition}, __MODULE__)
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
          last_result: LastResult.new(:visit, %{path: current_path, transition: transition}, StaticSession)
        }
    end
  end

  @doc false
  @spec follow_redirect(Session.t(), String.t()) :: Session.t()
  def follow_redirect(%__MODULE__{} = session, to) when is_binary(to) do
    visit(session, to, [])
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.click(locator, opts)
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
              candidate_values: click_candidate_values(session, match_opts, kind),
              texts: Html.texts(session.html, :any, Session.scope(session)),
              transition: session_transition(session)
            }

            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{} = locator, value, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_fill_in(session, expected, value, match_opts)

      :static ->
        case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
            updated = %{
              session
              | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
            }

            observed = %{
              action: :fill_in,
              path: session.current_path,
              field: field,
              value: value,
              transition: session_transition(session)
            }

            {:ok, update_session(updated, :fill_in, observed), observed}

          {:ok, _field} ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              candidate_values: field_candidate_values(session, match_opts),
              transition: session_transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def select(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)
    option = Keyword.fetch!(opts, :option)

    case route_kind(session) do
      :live ->
        do_live_select(session, expected, option, match_opts)

      :static ->
        select_in_static_mode(session, expected, option, match_opts)
    end
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_choose(session, expected, match_opts)

      :static ->
        choose_in_static_mode(session, expected, match_opts)
    end
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_toggle_checkbox(session, expected, match_opts, true, :check)

      :static ->
        case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
            value = FormData.toggled_checkbox_value(session, field, true)

            updated = %{
              session
              | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
            }

            observed = %{
              action: :check,
              path: session.current_path,
              field: field,
              checked: true,
              transition: session_transition(session)
            }

            {:ok, update_session(updated, :check, observed), observed}

          {:ok, %{name: name}} when is_binary(name) and name != "" ->
            observed = %{
              action: :check,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched field is not a checkbox"}

          {:ok, _field} ->
            observed = %{
              action: :check,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :check,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        do_live_toggle_checkbox(session, expected, match_opts, false, :uncheck)

      :static ->
        case Html.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
            value = FormData.toggled_checkbox_value(session, field, false)

            updated = %{
              session
              | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
            }

            observed = %{
              action: :uncheck,
              path: session.current_path,
              field: field,
              checked: false,
              transition: session_transition(session)
            }

            {:ok, update_session(updated, :uncheck, observed), observed}

          {:ok, %{name: name}} when is_binary(name) and name != "" ->
            observed = %{
              action: :uncheck,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched field is not a checkbox"}

          {:ok, _field} ->
            observed = %{
              action: :uncheck,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched field does not include a name attribute"}

          :error ->
            observed = %{
              action: :uncheck,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "no form field matched locator"}
        end
    end
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{} = locator, path, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        case LiveViewHTML.find_form_field(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
            do_live_upload(session, field, path)

          {:ok, _field} ->
            observed = %{
              action: :upload,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched upload field does not include a name attribute"}

          :error ->
            observed = %{
              action: :upload,
              path: session.current_path,
              candidate_values: field_candidate_values(session, match_opts),
              transition: session_transition(session)
            }

            {:error, session, observed, "no file input matched locator"}
        end

      :static ->
        upload_in_static_mode(session, expected, path, match_opts)
    end
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.submit(locator, opts)

    case route_kind(session) do
      :live ->
        case LiveViewHTML.find_submit_button(session.html, expected, match_opts, Session.scope(session)) do
          {:ok, button} ->
            do_live_submit(session, button)

          :error ->
            observed = %{
              action: :submit,
              path: session.current_path,
              candidate_values: submit_candidate_values(session, match_opts),
              transition: session_transition(session)
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
              candidate_values: submit_candidate_values(session, match_opts),
              transition: session_transition(session)
            }

            {:error, session, observed, "no submit button matched locator"}
        end
    end
  end

  @impl true
  def submit_active_form(%__MODULE__{} = session, _opts) do
    session = with_latest_html(session)

    case active_form_submit_button(session) do
      {:ok, button} ->
        case route_kind(session) do
          :live -> do_live_submit(session, button)
          :static -> do_submit(session, button)
        end

      {:error, reason} ->
        observed = %{action: :submit, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, reason}
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    if locator_assertion_requires_locator_engine?(locator) do
      run_locator_assertion(session, locator, opts, :assert)
    else
      match_opts = locator_match_opts(locator, opts)
      visible = Keyword.get(opts, :visible, true)
      match_by = Keyword.get(match_opts, :match_by, :text)
      {session, texts} = assertion_values(session, visible, match_by)
      matched = Enum.filter(texts, &Query.match_text?(&1, expected, match_opts))

      observed = %{
        path: session.current_path,
        visible: visible,
        texts: texts,
        matched: matched,
        expected: expected,
        transition: session_transition(session)
      }

      case Query.assertion_count_outcome(length(matched), match_opts, :assert) do
        :ok ->
          {:ok, update_session(session, :assert_has, observed), observed}

        {:error, reason} ->
          {:error, session, observed, reason}
      end
    end
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{} = locator, opts) do
    run_locator_assertion(session, locator, opts, :assert)
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    if locator_assertion_requires_locator_engine?(locator) do
      run_locator_assertion(session, locator, opts, :refute)
    else
      match_opts = locator_match_opts(locator, opts)
      visible = Keyword.get(opts, :visible, true)
      match_by = Keyword.get(match_opts, :match_by, :text)
      {session, texts} = assertion_values(session, visible, match_by)
      matched = Enum.filter(texts, &Query.match_text?(&1, expected, match_opts))

      observed = %{
        path: session.current_path,
        visible: visible,
        texts: texts,
        matched: matched,
        expected: expected,
        transition: session_transition(session)
      }

      case Query.assertion_count_outcome(length(matched), match_opts, :refute) do
        :ok ->
          {:ok, update_session(session, :refute_has, observed), observed}

        {:error, reason} ->
          {:error, session, observed, reason}
      end
    end
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{} = locator, opts) do
    run_locator_assertion(session, locator, opts, :refute)
  end

  defp run_locator_assertion(%__MODULE__{} = session, %Locator{} = locator, opts, mode) when mode in [:assert, :refute] do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)
    visible = Keyword.get(opts, :visible, true)
    matched = Html.locator_assertion_values(session.html, locator, visible, Session.scope(session))

    observed = %{
      path: session.current_path,
      visible: visible,
      texts: matched,
      matched: matched,
      expected: locator,
      transition: session_transition(session)
    }

    case Query.assertion_count_outcome(length(matched), match_opts, mode) do
      :ok ->
        op = if(mode == :assert, do: :assert_has, else: :refute_has)
        {:ok, update_session(session, op, observed), observed}

      {:error, reason} ->
        {:error, session, observed, reason}
    end
  end

  defp locator_assertion_requires_locator_engine?(%Locator{opts: locator_opts}) do
    Keyword.has_key?(locator_opts, :selector) or
      Keyword.has_key?(locator_opts, :has) or
      Keyword.has_key?(locator_opts, :has_not) or
      Keyword.has_key?(locator_opts, :from)
  end

  @impl true
  def assert_download(%__MODULE__{} = session, filename, opts) when is_binary(filename) and is_list(opts) do
    case route_kind(session) do
      :live ->
        timeout_ms = Keyword.fetch!(opts, :timeout)

        session
        |> LiveViewTimeout.with_timeout(timeout_ms, &download_redirect_target!/1)
        |> DownloadAssertion.assert_from_conn!(filename)

      :static ->
        DownloadAssertion.assert_from_conn!(session, filename)
    end
  end

  defp download_redirect_target!(%StaticSession{} = timed_session), do: timed_session
  defp download_redirect_target!(%__MODULE__{view: nil} = timed_session), do: timed_session

  defp download_redirect_target!(_timed_session) do
    raise AssertionError,
      message: "assert_download/3 timed out waiting for live download redirect to a static response"
  end

  @impl true
  def default_assert_timeout_ms(%__MODULE__{} = session), do: session.assert_timeout_ms

  @impl true
  def run_path_assertion(%__MODULE__{} = session, expected, opts, timeout, op) when op in [:assert_path, :refute_path] do
    driver_opts = Keyword.put(opts, :timeout, timeout)

    LiveViewTimeout.with_timeout(session, timeout, fn timed_session ->
      timed_driver = path_assertion_driver_for_session!(timed_session)
      run_path_assertion_operation!(timed_driver, timed_session, expected, driver_opts, op)
    end)
  end

  @impl true
  def assert_path(%__MODULE__{} = session, expected, opts) when is_binary(expected) or is_struct(expected, Regex) do
    observed = build_path_observed(session, expected, opts)

    if observed.path_match? and observed.query_match? do
      {:ok, update_last_result(session, :assert_path, observed), observed}
    else
      {:error, session, observed, "expected path assertion did not hold"}
    end
  end

  @impl true
  def refute_path(%__MODULE__{} = session, expected, opts) when is_binary(expected) or is_struct(expected, Regex) do
    observed = build_path_observed(session, expected, opts)

    if observed.path_match? and observed.query_match? do
      {:error, session, observed, "expected path assertion did not hold"}
    else
      {:ok, update_last_result(session, :refute_path, observed), observed}
    end
  end

  defp build_path_observed(session, expected, opts) do
    actual_path = Session.current_path(session)
    exact = Keyword.fetch!(opts, :exact)

    %{
      path: actual_path,
      scope: Session.scope(session),
      expected: expected,
      query: Cerberus.Path.normalize_expected_query(Keyword.get(opts, :query)),
      exact: exact,
      timeout: Keyword.get(opts, :timeout, 0),
      path_match?: Cerberus.Path.match_path?(actual_path, expected, exact: exact),
      query_match?: Cerberus.Path.query_matches?(actual_path, Keyword.get(opts, :query))
    }
  end

  defp run_path_assertion_operation!(driver, session, expected, driver_opts, op) do
    case apply(driver, op, [session, expected, driver_opts]) do
      {:ok, updated_session, _observed} ->
        updated_session

      {:error, _failed_session, observed, _reason} ->
        raise AssertionError,
          message: Cerberus.Path.format_assertion_error(Atom.to_string(op), observed)
    end
  end

  defp path_assertion_driver_for_session!(%__MODULE__{}), do: __MODULE__
  defp path_assertion_driver_for_session!(%StaticSession{}), do: StaticSession

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
          result: other,
          transition: session_transition(session)
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
        transition: session_transition(session)
      }

      {:error, session, observed, "dispatch(change) requires a resolvable form selector"}
    end
  end

  defp dispatch_change_payload(session, button, form_selector) do
    defaults = Html.form_defaults(session.html, form_selector, Session.scope(session))
    active = FormData.pruned_params_for_form(session, button.form, form_selector)

    defaults
    |> Map.merge(active)
    |> FormData.decode_query_params()
  end

  defp dispatch_change_target(button) do
    case FormData.button_payload(button) do
      {name, _value} -> FormData.target_path(name)
      nil -> nil
    end
  end

  defp dispatch_change_additional_payload(button, target) do
    additional = FormData.button_payload_map(button)

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
      details: details,
      transition: session_transition(session)
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
        driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: :link,
      path: Session.current_path(updated),
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
    case live_button_selector(button) do
      selector when is_binary(selector) and selector != "" ->
        element(view, scoped_selector(selector, scope))

      _ ->
        raise ArgumentError, "live button click requires a resolvable selector"
    end
  end

  defp live_link_element(view, %{selector: selector}, scope) when is_binary(selector) and selector != "" do
    element(view, scoped_selector(selector, scope))
  end

  defp live_link_element(view, link, scope) do
    case live_link_selector(link) do
      selector when is_binary(selector) and selector != "" ->
        element(view, scoped_selector(selector, scope))

      _ ->
        raise ArgumentError, "live link click requires a resolvable selector"
    end
  end

  defp live_button_selector(button) when is_map(button) do
    Enum.find(
      [
        attr_selector("button", "data-testid", Map.get(button, :testid)),
        attr_selector("button", "title", Map.get(button, :title)),
        attr_selector("button", "aria-label", Map.get(button, :aria_label)),
        attr_selector("button", "name", Map.get(button, :button_name)),
        attr_selector("button", "value", Map.get(button, :button_value)),
        attr_selector("button", "form", Map.get(button, :form))
      ],
      &(is_binary(&1) and &1 != "")
    )
  end

  defp live_link_selector(link) when is_map(link) do
    Enum.find(
      [
        attr_selector("a", "data-testid", Map.get(link, :testid)),
        attr_selector("a", "title", Map.get(link, :title)),
        attr_selector("a", "aria-label", Map.get(link, :aria_label)),
        attr_selector("a", "href", Map.get(link, :href))
      ],
      &(is_binary(&1) and &1 != "")
    )
  end

  defp attr_selector(tag, attr_name, value)
       when is_binary(tag) and is_binary(attr_name) and is_binary(value) and value != "" do
    ~s(#{tag}[#{attr_name}="#{css_attr_escape(value)}"])
  end

  defp attr_selector(_tag, _attr_name, _value), do: nil

  defp css_attr_escape(value) do
    value
    |> String.to_charlist()
    |> Enum.map_join(&css_attr_char_escape/1)
  end

  defp css_attr_char_escape(?\\), do: "\\\\"
  defp css_attr_char_escape(?"), do: "\\\""
  defp css_attr_char_escape(char) when char in [?\n, ?\r, ?\t, ?\f], do: "\\#{Integer.to_string(char, 16)} "
  defp css_attr_char_escape(char), do: <<char::utf8>>

  defp redirected_result(session, clicked, to, reason, action \\ :button) do
    updated = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: action,
      clicked: clicked.text,
      path: Session.current_path(updated),
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

  defp assertion_values(session, visibility, :text) do
    assertion_texts(session, visibility)
  end

  defp assertion_values(%__MODULE__{} = session, visibility, match_by) do
    session = with_latest_html(session)
    {session, Html.assertion_values(session.html, match_by, visibility, Session.scope(session))}
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

  defp resolve_within_scope!(session, locator, previous_scope) do
    case Html.find_scope_target(session_html!(session), locator, previous_scope) do
      {:ok, %{selector: selector}} when is_binary(selector) and selector != "" ->
        selector

      {:error, reason} ->
        raise AssertionError, message: "within/3 failed: #{reason}"
    end
  end

  defp session_html!(%{html: html}) when is_binary(html), do: html
  defp session_html!(_session), do: raise(ArgumentError, "within/3 requires a session with rendered html")

  defp restore_scope!(%{__struct__: _} = session, previous_scope) do
    Session.with_scope(session, previous_scope)
  end

  defp restore_scope!(_value, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp live_child_scope_candidate(%Locator{kind: :css, value: scope}, previous_scope, resolved_scope)
       when previous_scope in [nil, ""] and is_binary(scope) and scope != "" do
    if simple_id_selector?(scope), do: scope, else: resolved_scope
  end

  defp live_child_scope_candidate(_locator, _previous_scope, resolved_scope), do: resolved_scope

  defp restore_live_child_scope!(%{__struct__: _} = callback_result, parent_session, previous_scope) do
    case callback_result do
      %__MODULE__{} = live_result ->
        if Session.current_path(live_result) == Session.current_path(parent_session) do
          live_result
          |> Map.put(:view, parent_session.view)
          |> Map.put(:html, Phoenix.LiveViewTest.render(parent_session.view))
          |> Session.with_scope(previous_scope)
        else
          Session.with_scope(live_result, previous_scope)
        end

      _ ->
        Session.with_scope(callback_result, previous_scope)
    end
  end

  defp restore_live_child_scope!(_value, _parent_session, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp live_child_view_for_scope(%__MODULE__{view: %View{} = view}, scope) when is_binary(scope) do
    if simple_id_selector?(scope) do
      case Phoenix.LiveViewTest.find_live_child(view, String.trim_leading(scope, "#")) do
        %View{} = child_view -> {:ok, child_view}
        _ -> :error
      end
    else
      :error
    end
  end

  defp live_child_view_for_scope(_session, _scope), do: :error

  defp simple_id_selector?(scope), do: String.match?(scope, ~r/^#[A-Za-z_][A-Za-z0-9_-]*$/)

  defp ensure_same_endpoint!(%{endpoint: endpoint}, %{endpoint: endpoint}), do: :ok

  defp ensure_same_endpoint!(_session, _target_session) do
    raise ArgumentError, "cannot switch tab across sessions with different endpoints"
  end

  defp update_session(%__MODULE__{} = session, op, observed) do
    %{session | last_result: LastResult.new(op, observed, session)}
  end

  defp update_last_result(%__MODULE__{} = session, op, observed) do
    %{session | last_result: LastResult.new(op, observed, session)}
  end

  defp update_last_result(%StaticSession{} = session, op, observed) do
    %{session | last_result: LastResult.new(op, observed, session)}
  end

  defp find_clickable_link(_session, _expected, _opts, :button), do: :error

  defp find_clickable_link(session, expected, opts, _kind) do
    Html.find_link(session.html, expected, opts, Session.scope(session))
  end

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(%{view: view} = session, expected, opts, _kind) when not is_nil(view) do
    LiveViewHTML.find_live_clickable_button(session.html, expected, opts, Session.scope(session))
  end

  defp find_clickable_button(%__MODULE__{} = session, expected, opts, _kind) do
    Html.find_button(session.html, expected, opts, Session.scope(session))
  end

  defp click_button_error(:button), do: "live driver can only click buttons on live routes for click_button"
  defp click_button_error(_kind), do: "live driver can only click buttons on live routes"

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp click_candidate_values(session, match_opts, kind) do
    scope = Session.scope(session)
    match_by = Keyword.get(match_opts, :match_by, :text)

    values =
      case {kind, match_by} do
        {:link, :text} ->
          Html.assertion_values(session.html, :link, :any, scope)

        {:button, :text} ->
          Html.assertion_values(session.html, :button, :any, scope)

        {:any, :text} ->
          Html.assertion_values(session.html, :link, :any, scope) ++
            Html.assertion_values(session.html, :button, :any, scope)

        _ ->
          Html.assertion_values(session.html, match_by, :any, scope)
      end

    Enum.uniq(values)
  end

  defp field_candidate_values(session, match_opts) do
    match_by = Keyword.get(match_opts, :match_by, :label)
    Html.assertion_values(session.html, match_by, :any, Session.scope(session))
  end

  defp submit_candidate_values(session, match_opts) do
    match_by =
      case Keyword.get(match_opts, :match_by, :text) do
        :text -> :button
        other -> other
      end

    Html.assertion_values(session.html, match_by, :any, Session.scope(session))
  end

  defp active_form_submit_button(session) do
    case FormData.active_form_selector(session.form_data) do
      selector when is_binary(selector) and selector != "" ->
        selector
        |> find_active_form_submit_button(session)
        |> normalize_active_submit_button_result()

      _ ->
        no_active_form_submit_error()
    end
  end

  defp find_active_form_submit_button(selector, session) when is_binary(selector) do
    match_opts = [match_by: :button, selector: selector <> " button"]
    finder = submit_button_finder(route_kind(session))
    finder.(session.html, "", match_opts, Session.scope(session))
  end

  defp normalize_active_submit_button_result({:ok, button}), do: {:ok, button}

  defp normalize_active_submit_button_result(:error),
    do: {:error, "submit/1 could not find a submit button in the active form"}

  defp submit_button_finder(:live), do: &LiveViewHTML.find_submit_button/4
  defp submit_button_finder(:static), do: &Html.find_submit_button/4

  defp no_active_form_submit_error do
    {:error, "submit/1 requires an active form; call fill_in/select/choose/check/uncheck/upload first"}
  end

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
        transition: session_transition(session)
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
        field: field,
        transition: session_transition(session)
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
          field: field,
          file_name: file_name,
          result: other,
          transition: session_transition(session)
        }

        {:error, session, observed, "unexpected live upload result"}
    end
  end

  defp upload_redirect_result(session, field, file_name, to, reason) do
    updated = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: :upload,
      path: Session.current_path(updated),
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
      form_selector = FormData.submit_form_selector(button)
      submitted_params = FormData.params_for_submit(session, button, form_selector)

      target =
        button
        |> Map.get(:action)
        |> build_submit_target(session.current_path, submitted_params)

      updated = visit(session, target, [])

      transition =
        transition(
          route_kind(session),
          driver_kind(updated),
          :submit,
          session.current_path,
          Session.current_path(updated)
        )

      observed = %{
        action: :submit,
        clicked: button.text,
        path: Session.current_path(updated),
        method: method,
        params: submitted_params,
        transition: transition
      }

      cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form, button.form_selector)
      {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}
    else
      observed = %{
        action: :submit,
        clicked: button.text,
        path: session.current_path,
        transition: session_transition(session)
      }

      {:error, session, observed, "live driver static mode only supports GET form submissions"}
    end
  end

  defp do_live_submit(session, button) do
    form_payload = FormData.submit_form_payload(session, button)
    additional = FormData.button_payload_map(button)

    if button[:form_phx_submit] do
      do_live_phx_submit(session, button, form_payload, additional)
    else
      params = Map.merge(form_payload, additional)
      do_live_action_submit(session, button, params)
    end
  end

  defp do_live_phx_submit(session, button, form_payload, additional) do
    form_selector = FormData.submit_form_selector(button)

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
        transition: session_transition(session)
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
          params: params,
          transition: transition
        }

        cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form, button.form_selector)
        {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: session.current_path,
          details: details,
          transition: session_transition(session)
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
          params: submitted_params,
          transition: transition
        }

        cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form, button.form_selector)
        {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: session.current_path,
          details: details,
          transition: session_transition(session)
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
          params: submitted_params,
          transition: transition
        }

        cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form, button.form_selector)
        {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          path: session.current_path,
          details: details,
          transition: session_transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp resolve_live_submit_result(session, other, _button, _submitted_params) do
    observed = %{
      action: :submit,
      path: session.current_path,
      result: other,
      transition: session_transition(session)
    }

    {:error, session, observed, "unexpected live submit result"}
  end

  defp submitted_redirect_result(session, button, to, submitted_params, reason) do
    updated = visit(session, to, [])

    transition =
      transition(
        route_kind(session),
        driver_kind(updated),
        reason,
        session.current_path,
        Session.current_path(updated)
      )

    observed = %{
      action: :submit,
      clicked: button.text,
      path: Session.current_path(updated),
      method: normalize_submit_method(button.method),
      params: submitted_params,
      transition: transition
    }

    cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form, button.form_selector)
    {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}
  end

  defp select_in_static_mode(session, expected, option, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "select"} = field} when is_binary(name) and name != "" ->
        case Html.select_values(session.html, field, option, opts, Session.scope(session)) do
          {:ok, %{values: values, multiple?: multiple?}} ->
            value = FormData.select_value_for_update(session, field, option, values, multiple?, :static)

            updated = %{
              session
              | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
            }

            observed = %{
              action: :select,
              path: session.current_path,
              field: field,
              option: option,
              value: value,
              transition: session_transition(session)
            }

            {:ok, update_session(updated, :select, observed), observed}

          {:error, reason} ->
            observed = %{
              action: :select,
              path: session.current_path,
              field: field,
              option: option,
              transition: session_transition(session)
            }

            {:error, session, observed, reason}
        end

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{
          action: :select,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched field is not a select element"}

      {:ok, _field} ->
        observed = %{
          action: :select,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{
          action: :select,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp choose_in_static_mode(session, expected, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "radio"} = field} when is_binary(name) and name != "" ->
        value = field[:input_value] || "on"

        updated = %{
          session
          | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
        }

        observed = %{
          action: :choose,
          path: session.current_path,
          field: field,
          value: value,
          transition: session_transition(session)
        }

        {:ok, update_session(updated, :choose, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{
          action: :choose,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched field is not a radio input"}

      {:ok, _field} ->
        observed = %{
          action: :choose,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{
          action: :choose,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp upload_in_static_mode(session, expected, path, opts) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "file"} = field} when is_binary(name) and name != "" ->
        file = UploadFile.read!(path)
        value = FormData.upload_value_for_update(session, field, file, path, :static)

        updated = %{
          session
          | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
        }

        observed = %{
          action: :upload,
          path: session.current_path,
          field: field,
          file_name: file.file_name,
          transition: session_transition(session)
        }

        {:ok, update_session(updated, :upload, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{
          action: :upload,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched field is not a file input"}

      {:ok, _field} ->
        observed = %{
          action: :upload,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched upload field does not include a name attribute"}

      :error ->
        observed = %{
          action: :upload,
          path: session.current_path,
          candidate_values: field_candidate_values(session, opts),
          transition: session_transition(session)
        }

        {:error, session, observed, "no file input matched locator"}
    end
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{
        action: :upload,
        path: session.current_path,
        transition: session_transition(session)
      }

      {:error, session, observed, Exception.message(error)}
  end

  defp do_live_select(session, expected, option, opts) do
    with {:ok, field} <- find_live_select_field(session, expected, opts),
         {:ok, %{values: values, multiple?: multiple?}} <-
           Html.select_values(session.html, field, option, opts, Session.scope(session)) do
      value = FormData.select_value_for_update(session, field, option, values, multiple?, :live)
      form_data = FormData.put_form_value(session.form_data, field.form, field.form_selector, field.name, value)
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
        form_data = FormData.put_form_value(session.form_data, field.form, field.form_selector, field.name, value)
        updated = %{session | form_data: form_data}
        handle_live_choose_change(session, updated, field, value)

      {:error, reason} ->
        live_choose_error(session, reason)
    end
  end

  defp find_live_select_field(session, expected, opts) do
    case LiveViewHTML.find_form_field(session.html, expected, opts, Session.scope(session)) do
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
    case LiveViewHTML.find_form_field(session.html, expected, opts, Session.scope(session)) do
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
          field: field,
          option: option,
          value: value,
          phx_change: change.triggered,
          target: change.target,
          transition: change.transition || session_transition(changed_session)
        }

        {:ok, update_last_result(changed_session, :select, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :select,
          path: session.current_path,
          field: field,
          option: option,
          value: value,
          details: details,
          transition: session_transition(session)
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
          field: field,
          value: value,
          phx_change: change.triggered,
          target: change.target,
          transition: change.transition || session_transition(changed_session)
        }

        {:ok, update_last_result(changed_session, :choose, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :choose,
          path: session.current_path,
          field: field,
          value: value,
          details: details,
          transition: session_transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp live_select_error(session, option, reason) do
    observed = %{
      action: :select,
      path: session.current_path,
      option: option,
      transition: session_transition(session)
    }

    {:error, session, observed, reason}
  end

  defp live_choose_error(session, reason) do
    observed = %{
      action: :choose,
      path: session.current_path,
      transition: session_transition(session)
    }

    {:error, session, observed, reason}
  end

  defp do_live_fill_in(session, expected, value, opts) do
    case LiveViewHTML.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
        form_data = FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
        updated = %{session | form_data: form_data}

        case maybe_trigger_live_change(updated, field) do
          {:ok, changed_session, change} ->
            observed = %{
              action: :fill_in,
              path: Session.current_path(changed_session),
              field: field,
              value: value,
              phx_change: change.triggered,
              target: change.target,
              transition: change.transition || session_transition(changed_session)
            }

            {:ok, update_last_result(changed_session, :fill_in, observed), observed}

          {:error, failed_session, reason, details} ->
            observed = %{
              action: :fill_in,
              path: session.current_path,
              field: field,
              value: value,
              details: details,
              transition: session_transition(session)
            }

            {:error, failed_session, observed, reason}
        end

      {:ok, _field} ->
        observed = %{
          action: :fill_in,
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{
          action: :fill_in,
          path: session.current_path,
          candidate_values: field_candidate_values(session, opts),
          transition: session_transition(session)
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
    case LiveViewHTML.find_form_field(session.html, expected, opts, Session.scope(session)) do
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
    value = FormData.toggled_checkbox_value(session, field, checked?)
    form_data = FormData.put_form_value(session.form_data, field.form, field.form_selector, field.name, value)
    updated = %{session | form_data: form_data}

    case maybe_trigger_live_change(updated, field) do
      {:ok, changed_session, change} ->
        observed = %{
          action: op,
          path: Session.current_path(changed_session),
          field: field,
          checked: checked?,
          phx_change: change.triggered,
          target: change.target,
          transition: change.transition || session_transition(changed_session)
        }

        {:ok, update_last_result(changed_session, op, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: op,
          path: session.current_path,
          field: field,
          checked: checked?,
          details: details,
          transition: session_transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp checkbox_error_observed(session, op) do
    %{
      action: op,
      path: session.current_path,
      transition: session_transition(session)
    }
  end

  defp clear_submitted_session(%__MODULE__{} = session, form_data, op, observed) do
    %{session | form_data: form_data, last_result: LastResult.new(op, observed, session)}
  end

  defp clear_submitted_session(%StaticSession{} = session, form_data, op, observed) do
    %{session | form_data: form_data, last_result: LastResult.new(op, observed, session)}
  end

  defp maybe_trigger_live_change(%__MODULE__{} = session, field) do
    cond do
      field[:input_phx_change] ->
        trigger_input_phx_change(session, field)

      field[:form_phx_change] ->
        trigger_form_phx_change(session, field)

      true ->
        {:ok, session, %{triggered: false, target: nil, transition: session_transition(session)}}
    end
  end

  defp trigger_input_phx_change(session, field) do
    target = FormData.target_path(field.name)
    selector = field[:selector]

    if is_binary(selector) and selector != "" do
      payload =
        session
        |> FormData.form_payload_for_change(field)
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
    target = FormData.target_path(field.name)
    form_selector = field[:form_selector]

    if is_binary(form_selector) and form_selector != "" do
      payload = FormData.form_payload_for_change(session, field)
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
        driver_kind(redirected),
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
        driver_kind(redirected),
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
            driver_kind(updated),
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
    case LiveViewHTML.trigger_action_forms(rendered) do
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
        cleared_form_data = FormData.clear_submitted_form(session.form_data, form[:form], form[:form_selector])
        {:ok, %{updated | form_data: cleared_form_data}}

      {:error, _failed_session, reason, details} ->
        {:error, reason, details}
    end
  end

  defp trigger_action_submit_payload(session, form) do
    active = FormData.pruned_params_for_form(session, form[:form], form[:form_selector])
    defaults = Map.get(form, :defaults, %{})
    defaults |> Map.merge(active) |> FormData.decode_query_params()
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
        driver_kind(updated),
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

  defp unwrap_conn_result(%Plug.Conn{} = conn, session, from_driver) when from_driver in [:static, :live] do
    case redirect_target(conn) do
      nil ->
        build_unwrap_session_from_conn(session, conn, from_driver)

      redirect_path ->
        redirected_session =
          session
          |> static_seed_from_session(conn)
          |> StaticSession.visit(redirect_path, [])

        unwrap_transition =
          transition(
            from_driver,
            driver_kind(redirected_session),
            :unwrap,
            session.current_path,
            Session.current_path(redirected_session)
          )

        update_last_result(redirected_session, :unwrap, %{
          path: Session.current_path(redirected_session),
          transition: unwrap_transition
        })
    end
  end

  defp unwrap_conn_result(other, _session, _from_driver) do
    raise ArgumentError,
          "unwrap callback must return a Plug.Conn in static mode, got: #{inspect(other)}"
  end

  defp unwrap_live_result({:ok, %Plug.Conn{} = conn}, %__MODULE__{} = session) do
    unwrap_conn_result(conn, session, :live)
  end

  defp unwrap_live_result(%Plug.Conn{} = conn, %__MODULE__{} = session) do
    unwrap_conn_result(conn, session, :live)
  end

  defp unwrap_live_result({:ok, %View{} = view, html}, %__MODULE__{} = session) when is_binary(html) do
    build_live_session_from_view(session, view, html)
  end

  defp unwrap_live_result({:ok, %View{} = view, _extra}, %__MODULE__{} = session) do
    build_live_session_from_view(session, view, Phoenix.LiveViewTest.render(view))
  end

  defp unwrap_live_result(%View{} = view, %__MODULE__{} = session) do
    build_live_session_from_view(session, view, Phoenix.LiveViewTest.render(view))
  end

  defp unwrap_live_result({:error, {kind, %{to: to}}}, %__MODULE__{} = session)
       when kind in [:redirect, :live_redirect] and is_binary(to) do
    redirected = follow_redirect(session, to)

    unwrap_transition =
      transition(
        :live,
        driver_kind(redirected),
        kind,
        session.current_path,
        Session.current_path(redirected)
      )

    update_last_result(redirected, :unwrap, %{
      path: Session.current_path(redirected),
      transition: unwrap_transition
    })
  end

  defp unwrap_live_result({:error, {:live_patch, %{to: to}}}, %__MODULE__{} = session) when is_binary(to) do
    path = Cerberus.Path.normalize(to) || session.current_path
    html = Phoenix.LiveViewTest.render(session.view)
    unwrap_transition = transition(:live, :live, :live_patch, session.current_path, path)

    session
    |> Map.put(:html, html)
    |> Map.put(:current_path, path)
    |> update_last_result(:unwrap, %{path: path, transition: unwrap_transition})
  end

  defp unwrap_live_result(rendered, %__MODULE__{} = session) when is_binary(rendered) do
    path = maybe_live_patch_path(session.view, session.current_path)
    unwrap_transition = transition(:live, :live, :unwrap, session.current_path, path)

    session
    |> Map.put(:html, rendered)
    |> Map.put(:current_path, path)
    |> update_last_result(:unwrap, %{path: path, transition: unwrap_transition})
  end

  defp unwrap_live_result(other, _session) do
    raise ArgumentError,
          "unwrap callback in live mode must return render output, redirect tuple, view, or Plug.Conn; got: #{inspect(other)}"
  end

  defp build_unwrap_session_from_conn(session, conn, from_driver) do
    current_path = Conn.current_path(conn, session.current_path)

    case try_live(conn) do
      {:ok, view, html} ->
        unwrap_transition = transition(from_driver, :live, :unwrap, session.current_path, current_path)

        %__MODULE__{
          endpoint: session.endpoint,
          conn: conn,
          view: view,
          html: html,
          form_data: Map.get(session, :form_data),
          scope: session.scope,
          current_path: current_path,
          last_result: LastResult.new(:unwrap, %{path: current_path, transition: unwrap_transition}, __MODULE__)
        }

      :error ->
        unwrap_transition = transition(from_driver, :static, :unwrap, session.current_path, current_path)

        %StaticSession{
          endpoint: session.endpoint,
          conn: conn,
          html: conn.resp_body || "",
          form_data: Map.get(session, :form_data),
          scope: session.scope,
          current_path: current_path,
          last_result: LastResult.new(:unwrap, %{path: current_path, transition: unwrap_transition}, StaticSession)
        }
    end
  end

  defp build_live_session_from_view(session, view, html) do
    path = maybe_live_patch_path(view, session.current_path)
    unwrap_transition = transition(:live, :live, :unwrap, session.current_path, path)

    session
    |> Map.put(:view, view)
    |> Map.put(:html, html)
    |> Map.put(:current_path, path)
    |> update_last_result(:unwrap, %{path: path, transition: unwrap_transition})
  end

  defp static_seed_from_session(session, conn) do
    %StaticSession{
      endpoint: session.endpoint,
      conn: conn,
      html: conn.resp_body || "",
      form_data: Map.get(session, :form_data),
      scope: session.scope,
      current_path: Conn.current_path(conn, session.current_path),
      last_result: session.last_result
    }
  end

  defp redirect_target(%Plug.Conn{status: status} = conn) when status in 300..399 do
    case Plug.Conn.get_resp_header(conn, "location") do
      [location | _] -> Cerberus.Path.normalize(location)
      _ -> nil
    end
  end

  defp redirect_target(_conn), do: nil

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

  defp session_transition(%{last_result: %{transition: transition}}), do: transition
  defp session_transition(_session), do: nil

  defp driver_kind(%__MODULE__{}), do: :live
  defp driver_kind(%StaticSession{}), do: :static
end
