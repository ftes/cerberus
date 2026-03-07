defmodule Cerberus.Driver.Live do
  @moduledoc false

  @behaviour Cerberus.Driver

  import Phoenix.LiveViewTest, only: [element: 2, element: 3, render: 1, render_click: 2]

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.CandidateScope
  alias Cerberus.Driver.DownloadAssertion
  alias Cerberus.Driver.Live.FormData
  alias Cerberus.Driver.LocatorOps
  alias Cerberus.Driver.SelectorFallback
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
  alias Phoenix.LiveView.Utils
  alias Phoenix.LiveViewTest.TreeDOM
  alias Phoenix.LiveViewTest.View

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          timeout_ms: non_neg_integer(),
          timeout_overridden?: boolean(),
          view: term() | nil,
          html: String.t(),
          form_data: map(),
          scope: Session.scope_value(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            timeout_ms: 0,
            timeout_overridden?: false,
            view: nil,
            html: "",
            form_data: %{active_form: nil, active_form_selector: nil, values: %{}},
            scope: nil,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    {timeout_ms, timeout_overridden?} = SessionConfig.timeout_from_opts!(opts, :live)

    %__MODULE__{
      endpoint: Conn.endpoint!(opts),
      conn: initial_conn(opts),
      timeout_ms: timeout_ms,
      timeout_overridden?: timeout_overridden?
    }
  end

  @impl true
  @spec open_tab(t()) :: t()
  def open_tab(%__MODULE__{} = session) do
    new_session(
      endpoint: session.endpoint,
      conn: Conn.fork_tab_conn(session.conn),
      timeout_ms: session.timeout_ms,
      timeout_overridden?: session.timeout_overridden?
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
  def open_browser(%__MODULE__{view: %{pid: pid} = view} = session, open_fun)
      when is_function(open_fun, 1) and is_pid(pid) do
    if Process.alive?(pid) do
      _ = Phoenix.LiveViewTest.open_browser(view, open_fun)
      session
    else
      open_browser_snapshot(session, open_fun)
    end
  end

  def open_browser(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
    open_browser_snapshot(session, open_fun)
  end

  defp open_browser_snapshot(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
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
          timeout_ms: timeout_for_driver(session, :static),
          timeout_overridden?: session.timeout_overridden?,
          html: html,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: LastResult.new(:visit, %{path: current_path, transition: transition}, StaticSession)
        }
    end
  end

  @doc false
  @spec follow_redirect(
          Session.t(),
          String.t()
          | {String.t(), map() | nil}
          | %{required(:to) => String.t(), optional(atom()) => term()}
        ) :: Session.t()
  def follow_redirect(%__MODULE__{} = session, to) when is_binary(to) do
    visit(session, to, [])
  end

  def follow_redirect(%__MODULE__{} = session, {to, flash}) when is_binary(to) do
    request_path = to_request_path(to, session.current_path)

    conn =
      session.conn
      |> Conn.ensure_conn()
      |> maybe_put_flash_cookie(session.endpoint, flash)
      |> then(&Conn.follow_get(session.endpoint, &1, request_path))

    session
    |> session_from_conn(conn, request_path)
    |> maybe_store_follow_redirect_flash(flash)
  end

  def follow_redirect(%__MODULE__{} = session, %{to: to, flash: flash}) when is_binary(to) do
    follow_redirect(session, {to, flash})
  end

  def follow_redirect(%__MODULE__{} = session, %{to: to}) when is_binary(to) do
    follow_redirect(session, to)
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{} = locator, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.click(locator, opts)
    kind = Keyword.get(match_opts, :kind, :any)
    maybe_raise_live_link_ambiguity!(session, expected, match_opts, kind)

    case find_clickable_link(session, expected, match_opts, kind) do
      {:ok, link} when is_binary(link.href) ->
        click_resolved_link(session, link)

      :error ->
        case wait_for_live_clickable_button(session, expected, match_opts, kind) do
          {:ok, action_session, button} ->
            click_or_error_for_button(action_session, button, kind)

          {:error, action_session, "no button matched locator"} ->
            observed = %{
              action: :click,
              path: action_session.current_path,
              candidate_values: click_candidate_values(action_session, match_opts, kind),
              texts: Html.texts(action_session.html, :any, Session.scope(action_session)),
              transition: session_transition(action_session)
            }

            {:error, action_session, observed, no_clickable_error(kind)}

          {:error, action_session, reason} ->
            observed = %{
              action: :click,
              path: action_session.current_path,
              candidate_values: click_candidate_values(action_session, match_opts, kind),
              texts: Html.texts(action_session.html, :any, Session.scope(action_session)),
              transition: session_transition(action_session)
            }

            {:error, action_session, observed, reason}
        end
    end
  end

  defp click_resolved_link(session, link) do
    if live_route?(session) do
      case click_live_data_method(session, link, :link) do
        :not_data_method -> click_live_link(session, link)
        result -> result
      end
    else
      click_link_via_visit(session, link, :click)
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{} = locator, value, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        case wait_for_live_form_field(session, expected, match_opts, :fill_in) do
          {:ok, action_session, field} ->
            do_live_fill_in(action_session, field, value)

          {:error, failed_session, reason} ->
            observed = %{
              action: :fill_in,
              path: failed_session.current_path,
              candidate_values: field_candidate_values(failed_session, match_opts),
              transition: session_transition(failed_session)
            }

            {:error, failed_session, observed, reason}
        end

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
        case wait_for_live_form_field(session, expected, match_opts, :select) do
          {:ok, action_session, field} ->
            do_live_select(action_session, field, option, match_opts)

          {:error, failed_session, reason} ->
            live_select_error(failed_session, option, reason)
        end

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
        case wait_for_live_form_field(session, expected, match_opts, :choose) do
          {:ok, action_session, field} ->
            do_live_choose(action_session, field)

          {:error, failed_session, reason} ->
            live_choose_error(failed_session, reason)
        end

      :static ->
        choose_in_static_mode(session, expected, match_opts)
    end
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{} = locator, opts) do
    toggle_checkbox(session, locator, opts, true, :check)
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{} = locator, opts) do
    toggle_checkbox(session, locator, opts, false, :uncheck)
  end

  defp toggle_checkbox(%__MODULE__{} = session, %Locator{} = locator, opts, checked?, op) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        case wait_for_live_form_field(session, expected, match_opts, op) do
          {:ok, action_session, field} ->
            do_live_toggle_checkbox(action_session, field, checked?, op)

          {:error, failed_session, reason} ->
            observed = checkbox_error_observed(failed_session, op)
            {:error, failed_session, observed, reason}
        end

      :static ->
        toggle_checkbox_in_static_mode(session, expected, match_opts, checked?, op)
    end
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{} = locator, path, opts) do
    session = with_latest_html(session)
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case route_kind(session) do
      :live ->
        case wait_for_live_form_field(session, expected, match_opts, :upload) do
          {:ok, action_session, field} ->
            do_live_upload(action_session, field, path)

          {:error, failed_session, reason} ->
            observed = %{
              action: :upload,
              path: failed_session.current_path,
              candidate_values: field_candidate_values(failed_session, match_opts),
              transition: session_transition(failed_session)
            }

            {:error, failed_session, observed, reason}
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
        case wait_for_live_submit_button(session, expected, match_opts) do
          {:ok, action_session, button} ->
            do_live_submit(action_session, button)

          {:error, failed_session, reason} ->
            observed = %{
              action: :submit,
              path: failed_session.current_path,
              candidate_values: submit_candidate_values(failed_session, match_opts),
              transition: session_transition(failed_session)
            }

            {:error, failed_session, observed, reason}
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
          :live -> do_live_submit(session, preserve_live_active_form_button(button))
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

  @impl true
  def assert_value(%__MODULE__{} = session, %Locator{} = locator, expected, opts)
      when (is_binary(expected) or is_struct(expected, Regex)) and is_list(opts) do
    run_value_assertion(session, locator, expected, opts, :assert)
  end

  @impl true
  def refute_value(%__MODULE__{} = session, %Locator{} = locator, expected, opts)
      when (is_binary(expected) or is_struct(expected, Regex)) and is_list(opts) do
    run_value_assertion(session, locator, expected, opts, :refute)
  end

  defp run_value_assertion(%__MODULE__{} = session, %Locator{} = locator, expected, opts, mode)
       when mode in [:assert, :refute] do
    session = with_latest_html(session)
    {field_expected, match_opts} = LocatorOps.form(locator, opts)
    op = value_assertion_op(mode)

    case Html.find_form_field(session.html, field_expected, match_opts, Session.scope(session)) do
      {:ok, field} ->
        value = current_field_value(session, field)
        matched? = value_matches?(value, expected)
        observed = value_assertion_observed(session, field, expected, value)

        if value_assertion_satisfied?(mode, matched?) do
          {:ok, update_session(session, op, observed), observed}
        else
          {:error, session, observed, value_assertion_reason(mode)}
        end

      :error ->
        observed = %{
          path: session.current_path,
          expected: expected,
          candidate_values: field_candidate_values(session, match_opts),
          transition: session_transition(session)
        }

        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp run_locator_assertion(%__MODULE__{} = session, %Locator{} = locator, opts, mode) when mode in [:assert, :refute] do
    session = with_latest_html(session)
    match_opts = locator_match_opts(locator, opts)
    visible = assertion_visibility(opts, locator)

    case locator_assertion_values(session, locator, visible) do
      {:ok, matched} ->
        finalize_locator_assertion(session, locator, visible, matched, match_opts, mode)

      {:error, reason} ->
        observed = %{
          path: session.current_path,
          visible: visible,
          texts: [],
          matched: [],
          expected: locator,
          transition: session_transition(session)
        }

        {:error, session, observed, reason}
    end
  end

  defp finalize_locator_assertion(session, locator, visible, matched, match_opts, mode) do
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

  defp locator_assertion_values(%__MODULE__{} = session, %Locator{} = locator, visible) do
    matched = Html.locator_assertion_values(session.html, locator, visible, Session.scope(session))

    matched =
      if matched == [] do
        case SelectorFallback.selected_option_assertion_values(session.form_data, locator, visible) do
          nil -> matched
          fallback -> fallback
        end
      else
        matched
      end

    {:ok, matched}
  catch
    kind, reason ->
      case {kind, reason} do
        {:throw, {throw_key, _deadline_ms}} when is_atom(throw_key) ->
          if throw_key == Html.assertion_deadline_throw() do
            {:error, "assertion timed out while resolving locator candidates"}
          else
            :erlang.raise(kind, reason, __STACKTRACE__)
          end

        _ ->
          :erlang.raise(kind, reason, __STACKTRACE__)
      end
  end

  defp locator_assertion_requires_locator_engine?(%Locator{opts: locator_opts}) do
    Keyword.has_key?(locator_opts, :has) or
      Keyword.has_key?(locator_opts, :has_not) or
      Keyword.has_key?(locator_opts, :from) or
      Keyword.has_key?(locator_opts, :visible) or
      Keyword.has_key?(locator_opts, :checked) or
      Keyword.has_key?(locator_opts, :disabled) or
      Keyword.has_key?(locator_opts, :selected) or
      Keyword.has_key?(locator_opts, :readonly)
  end

  defp assertion_visibility(opts, %Locator{opts: locator_opts}) do
    case Keyword.get(locator_opts, :visible) do
      value when is_boolean(value) -> value
      _ -> Keyword.get(opts, :visible, true)
    end
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
  def default_timeout_ms(%__MODULE__{} = session), do: session.timeout_ms

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
      timeout: Keyword.get(opts, :timeout, session.timeout_ms),
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

  defp click_live_button(session, %{dispatch_change: true} = button, _kind) do
    click_live_dispatch_change_button(session, button)
  end

  defp click_live_button(session, button, kind) do
    result =
      try do
        session.view
        |> live_button_element(button, Session.scope(session))
        |> render_click(%{})
      rescue
        error in ArgumentError ->
          {:error, {:invalid_live_click, Exception.message(error)}}
      end

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

      {:error, {:invalid_live_click, reason}} ->
        observed = %{
          action: :button,
          clicked: button.text,
          path: session.current_path,
          result: reason,
          transition: session_transition(session)
        }

        {:error, session, observed, no_clickable_error(kind)}

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
    |> render_click(%{})
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
        case {live_button_tag_selector(button), Map.get(button, :text)} do
          {selector, text} when is_binary(selector) and selector != "" and is_binary(text) and text != "" ->
            element(view, scoped_selector(selector, scope), text)

          _ ->
            raise ArgumentError, "live button click requires a resolvable selector"
        end
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
    tag = live_button_tag_selector(button)

    Enum.find(
      [
        attr_selector(tag, "data-testid", Map.get(button, :testid)),
        attr_selector(tag, "title", Map.get(button, :title)),
        attr_selector(tag, "aria-label", Map.get(button, :aria_label)),
        attr_selector(tag, "name", Map.get(button, :button_name)),
        attr_selector(tag, "value", Map.get(button, :button_value)),
        attr_selector(tag, "form", Map.get(button, :form))
      ],
      &(is_binary(&1) and &1 != "")
    )
  end

  defp live_button_tag_selector(button) when is_map(button) do
    case Map.get(button, :tag, "button") do
      tag when is_binary(tag) and tag != "" -> tag
      _ -> "button"
    end
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

  defp maybe_raise_live_link_ambiguity!(_session, _expected, _opts, kind) when kind != :link do
    :ok
  end

  defp maybe_raise_live_link_ambiguity!(session, expected, opts, :link) do
    if simple_live_link_ambiguity_check?(opts) do
      match_count =
        live_link_match_count(session.html, expected, opts, CandidateScope.click_scope(opts, Session.scope(session)))

      if match_count > 1 do
        raise ArgumentError, "#{match_count} of them matched the text filter"
      end
    end
  end

  defp simple_live_link_ambiguity_check?(opts) do
    simple_link_locator?(Keyword.get(opts, :locator)) and
      not Query.has_count_constraints?(opts) and
      not Keyword.get(opts, :first, false) and
      not Keyword.get(opts, :last, false) and
      is_nil(Keyword.get(opts, :index)) and
      is_nil(Keyword.get(opts, :nth))
  end

  defp simple_link_locator?(%Locator{kind: :role} = locator), do: Locator.resolved_kind(locator) == :link
  defp simple_link_locator?(_), do: false

  defp live_link_match_count(html, expected, opts, scope) when is_binary(html) do
    lazy_html =
      try do
        LazyHTML.from_document(html)
      rescue
        _ -> nil
      end

    case lazy_html do
      %LazyHTML{} = root ->
        roots =
          if is_binary(scope) and scope != "" do
            safe_query(root, scope)
          else
            [root]
          end

        roots
        |> Enum.flat_map(&safe_query(&1, "a[href]"))
        |> Enum.count(fn node ->
          Query.match_text?(link_node_text(node), expected, opts) and
            Html.node_matches_locator_filters?(node, opts)
        end)

      _ ->
        0
    end
  end

  defp live_link_match_count(_html, _expected, _opts, _scope), do: 0

  defp link_node_text(node) do
    node
    |> LazyHTML.text()
    |> String.replace("\u00A0", " ")
    |> String.trim()
  end

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(%{view: view} = session, expected, opts, _kind) when not is_nil(view) do
    case LiveViewHTML.find_live_clickable_button(session.html, expected, opts, Session.scope(session)) do
      {:ok, button} ->
        {:ok, button}

      :error ->
        case LiveViewHTML.find_submit_button(session.html, expected, opts, Session.scope(session)) do
          {:ok, button} ->
            {:ok, button}

          :error ->
            Html.find_button(session.html, expected, opts, Session.scope(session))
        end
    end
  end

  defp find_clickable_button(%__MODULE__{} = session, expected, opts, _kind) do
    Html.find_button(session.html, expected, opts, Session.scope(session))
  end

  defp click_button_error(_kind), do: "live driver can only click buttons on live routes"

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp click_candidate_values(session, match_opts, kind) do
    scope = CandidateScope.click_scope(match_opts, Session.scope(session))
    match_by = Keyword.get(match_opts, :match_by, :text)
    css_scoped_text? = CandidateScope.css_scoped_text_candidates?(match_opts)

    values =
      case {css_scoped_text?, kind, match_by} do
        {true, _, :text} ->
          Html.assertion_values(session.html, :text, :any, scope)

        {false, :link, :text} ->
          Html.assertion_values(session.html, :link, :any, scope)

        {false, :button, :text} ->
          Html.assertion_values(session.html, :button, :any, scope)

        {false, :any, :text} ->
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

  defp value_assertion_satisfied?(:assert, matched?), do: matched?
  defp value_assertion_satisfied?(:refute, matched?), do: not matched?

  defp value_assertion_op(:assert), do: :assert_value
  defp value_assertion_op(:refute), do: :refute_value

  defp value_assertion_reason(:assert), do: "expected field value not found"
  defp value_assertion_reason(:refute), do: "unexpected matching field value found"

  defp value_matches?(actual, %Regex{} = expected), do: Regex.match?(expected, actual)
  defp value_matches?(actual, expected) when is_binary(expected), do: actual == expected

  defp value_assertion_observed(session, field, expected, value) do
    %{
      path: session.current_path,
      field: field,
      value: value,
      expected: expected,
      candidate_values: [value],
      transition: session_transition(session)
    }
  end

  defp current_field_value(session, field) do
    form_selector = field[:form_selector]
    defaults = form_defaults_for_selector(session, form_selector)
    active = FormData.pruned_params_for_form(session, field.form, form_selector)
    raw = Map.get(Map.merge(defaults, active), field.name)
    normalize_field_value(field, raw)
  end

  defp form_defaults_for_selector(_session, selector) when selector in [nil, ""], do: %{}

  defp form_defaults_for_selector(session, selector) do
    Html.form_defaults(session.html, selector, Session.scope(session))
  end

  defp normalize_field_value(%{input_type: type, input_value: input_value}, _raw) when type in ["checkbox", "radio"] do
    input_value || "on"
  end

  defp normalize_field_value(%{input_type: "file"}, %Plug.Upload{filename: filename}) when is_binary(filename),
    do: filename

  defp normalize_field_value(%{input_type: "select"}, raw), do: normalize_select_value(raw)
  defp normalize_field_value(_field, raw), do: normalize_scalar_value(raw)

  defp normalize_select_value([value | _rest]), do: normalize_scalar_value(value)
  defp normalize_select_value([]), do: ""
  defp normalize_select_value(value), do: normalize_scalar_value(value)

  defp normalize_scalar_value(value) when is_binary(value), do: value
  defp normalize_scalar_value(value) when is_integer(value) or is_float(value), do: to_string(value)
  defp normalize_scalar_value(true), do: "true"
  defp normalize_scalar_value(false), do: "false"
  defp normalize_scalar_value(%Plug.Upload{filename: filename}) when is_binary(filename), do: filename
  defp normalize_scalar_value([value | _rest]), do: normalize_scalar_value(value)
  defp normalize_scalar_value([]), do: ""
  defp normalize_scalar_value(nil), do: ""
  defp normalize_scalar_value(value), do: to_string(value)

  defp active_form_submit_button(session) do
    case FormData.active_form_selector(session.form_data) do
      selector when is_binary(selector) and selector != "" ->
        selector
        |> find_active_form_submit_button(session)
        |> normalize_active_submit_button_result(session, selector)

      _ ->
        no_active_form_submit_error()
    end
  end

  defp find_active_form_submit_button(selector, session) when is_binary(selector) do
    match_opts = [match_by: :button, selector: selector <> " button"]
    finder = submit_button_finder(route_kind(session))
    finder.(session.html, "", match_opts, Session.scope(session))
  end

  defp normalize_active_submit_button_result({:ok, button}, _session, _selector), do: {:ok, button}

  defp normalize_active_submit_button_result(:error, session, selector) do
    case active_form_submit_fallback(session, selector) do
      {:ok, button} -> {:ok, button}
      :error -> {:error, "submit/1 could not find a submit button in the active form"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp submit_button_finder(:live), do: &LiveViewHTML.find_submit_button/4
  defp submit_button_finder(:static), do: &Html.find_submit_button/4

  defp no_active_form_submit_error do
    {:error, "submit/1 requires an active form; call fill_in/select/choose/check/uncheck/upload first"}
  end

  defp active_form_submit_fallback(%__MODULE__{} = session, selector) when is_binary(selector) do
    with {:ok, attrs} <- active_form_attributes(session.html, selector) do
      form_phx_submit = present_attr?(Map.get(attrs, "phx-submit"))
      action = blank_to_nil(Map.get(attrs, "action"))

      if form_phx_submit or is_binary(action) do
        {:ok,
         %{
           text: "",
           action: action,
           method: blank_to_nil(Map.get(attrs, "method")),
           form: blank_to_nil(Map.get(attrs, "id")),
           form_selector: selector,
           form_phx_submit: form_phx_submit,
           button_name: nil,
           button_value: nil
         }}
      else
        {:error, "submit target form must have a `phx-submit` or `action` defined"}
      end
    end
  end

  defp active_form_attributes(html, selector) when is_binary(html) and is_binary(selector) do
    case form_id_from_selector(selector) do
      id when is_binary(id) ->
        escaped_id = Regex.escape(id)

        case Regex.run(~r/<form\b(?=[^>]*\bid=(['"])#{escaped_id}\1)([^>]*)>/is, html, capture: :all_but_first) do
          [_, attrs] -> {:ok, parse_html_attributes(attrs)}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp form_id_from_selector(selector) when is_binary(selector) do
    case Regex.run(~r/form\[id=(['"])([^'"]+)\1\]/, selector, capture: :all_but_first) do
      [_, id] ->
        id

      _ ->
        case Regex.run(~r/#([A-Za-z0-9_-]+)/, selector, capture: :all_but_first) do
          [id] -> id
          _ -> nil
        end
    end
  end

  defp parse_html_attributes(attrs) when is_binary(attrs) do
    ~r/([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(['"])(.*?)\2/s
    |> Regex.scan(attrs)
    |> Enum.reduce(%{}, fn [_, key, _quote, value], acc ->
      Map.put(acc, String.downcase(key), value)
    end)
  end

  defp present_attr?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_attr?(_), do: false
  defp blank_to_nil(value) when is_binary(value), do: if(String.trim(value) == "", do: nil, else: value)
  defp blank_to_nil(_), do: nil

  defp data_method_target(element) do
    blank_to_nil(Map.get(element, :data_to)) || blank_to_nil(Map.get(element, :href))
  end

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp click_or_error_for_button(session, button, kind) do
    if live_route?(session) do
      cond do
        Map.get(button, :disabled) ->
          observed = %{
            action: :button,
            clicked: button.text,
            path: session.current_path,
            transition: session_transition(session)
          }

          {:error, session, observed, "matched field is disabled"}

        present_attr?(Map.get(button, :data_method)) ->
          click_live_data_method(session, button, :button)

        submit_button_match?(button) ->
          click_live_submit_button(session, button)

        true ->
          click_live_button(session, button, kind)
      end
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

  defp click_live_data_method(session, element, action) do
    with {:ok, normalized_method} <- live_data_method_action(element, action),
         {:ok, target} <- data_method_target_result(element) do
      do_click_live_data_method(session, element, action, normalized_method, target)
    else
      :not_data_method ->
        :not_data_method

      {:error, :missing_target} ->
        live_data_method_target_error(session, element, action)
    end
  end

  defp live_data_method_action(element, action) do
    method = blank_to_nil(Map.get(element, :data_method))
    data_to = blank_to_nil(Map.get(element, :data_to))

    cond do
      not is_binary(method) -> :not_data_method
      action == :link and not is_binary(data_to) -> :not_data_method
      true -> {:ok, normalize_submit_method(method)}
    end
  end

  defp data_method_target_result(element) do
    case data_method_target(element) do
      target when is_binary(target) -> {:ok, target}
      _ -> {:error, :missing_target}
    end
  end

  defp live_data_method_target_error(session, element, action) do
    observed = %{
      action: action,
      clicked: element[:text] || "",
      path: session.current_path,
      transition: session_transition(session)
    }

    {:error, session, observed, "data-method element must define `data-to` or `href`"}
  end

  defp do_click_live_data_method(session, element, action, method, target) do
    case follow_form_request(session, method, target, %{}) do
      {:ok, updated, _transition} ->
        transition =
          transition(
            route_kind(session),
            driver_kind(updated),
            :click,
            session.current_path,
            Session.current_path(updated)
          )

        observed = %{
          action: action,
          clicked: element[:text] || "",
          method: method,
          path: Session.current_path(updated),
          texts: Html.texts(updated.html, :any, Session.scope(updated)),
          transition: transition
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: action,
          clicked: element[:text] || "",
          method: method,
          path: session.current_path,
          details: details,
          transition: session_transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp submit_button_match?(button) when is_map(button) do
    Map.has_key?(button, :form_phx_submit)
  end

  defp click_live_submit_button(session, button) do
    case do_live_submit(session, button) do
      {:ok, updated_session, observed} ->
        click_observed = Map.put(observed, :action, :button)
        {:ok, update_last_result(updated_session, :click, click_observed), click_observed}

      {:error, failed_session, observed, reason} ->
        click_observed = Map.put(observed, :action, :button)
        {:error, failed_session, click_observed, reason}
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
      action = blank_to_nil(button[:action])

      if is_binary(action) do
        params = Map.merge(form_payload, additional)
        do_live_action_submit(session, %{button | action: action}, params)
      else
        observed = %{
          action: :submit,
          clicked: button[:text] || "",
          path: session.current_path,
          transition: session_transition(session)
        }

        {:error, session, observed, "submit target form must have a `phx-submit` or `action` defined"}
      end
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

        cleared_form_data = submitted_form_data_after_success(session.form_data, button)
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

        cleared_form_data = submitted_form_data_after_success(session.form_data, button)
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

        cleared_form_data = submitted_form_data_after_success(session.form_data, button)
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

    cleared_form_data = submitted_form_data_after_success(session.form_data, button)
    {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}
  end

  defp preserve_live_active_form_button(button) when is_map(button) do
    if button[:form_phx_submit] do
      Map.put(button, :preserve_active_form, true)
    else
      button
    end
  end

  defp submitted_form_data_after_success(form_data, button) do
    if button[:preserve_active_form] do
      form_data
    else
      FormData.clear_submitted_form(form_data, button.form, button.form_selector)
    end
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

  defp do_live_select(session, field, option, opts) do
    case Html.select_values(session.html, field, option, opts, Session.scope(session)) do
      {:ok, %{values: values, multiple?: multiple?}} ->
        if select_requires_option_click?(field) and not select_has_option_clicks?(field) do
          raise ArgumentError, select_option_click_contract_error()
        end

        value = FormData.select_value_for_update(session, field, option, values, multiple?, :live)
        form_data = FormData.put_form_value(session.form_data, field.form, field.form_selector, field.name, value)
        updated = %{session | form_data: form_data}

        if select_requires_option_click?(field) do
          handle_live_select_option_clicks(session, updated, field, option, value, values)
        else
          handle_live_select_change(session, updated, field, option, value)
        end

      {:error, reason} ->
        live_select_error(session, option, reason)
    end
  end

  defp do_live_choose(session, field), do: apply_live_radio_change(session, field)

  defp apply_live_radio_change(session, field) do
    if radio_requires_phx_click?(field) and not field[:input_phx_click] do
      raise ArgumentError, radio_click_contract_error()
    end

    value = field[:input_value] || "on"

    form_data =
      if radio_click_without_name_supported?(field) do
        session.form_data
      else
        FormData.put_form_value(session.form_data, field.form, field.form_selector, field.name, value)
      end

    updated = %{session | form_data: form_data}

    change_result =
      if radio_requires_phx_click?(field) and field[:input_phx_click] do
        trigger_live_radio_click(updated, field, value)
      else
        maybe_trigger_live_change(updated, field)
      end

    handle_live_choose_change_result(session, change_result, field, value)
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

  defp handle_live_select_option_clicks(session, updated, field, option, value, selected_values) do
    case trigger_live_select_option_clicks(updated, field, selected_values) do
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

  defp handle_live_choose_change_result(session, change_result, field, value) do
    case change_result do
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

  defp select_requires_option_click?(field) do
    field[:form] in [nil, ""] and field[:form_selector] in [nil, ""]
  end

  defp select_has_option_clicks?(field) do
    field
    |> Map.get(:option_phx_click_selectors, %{})
    |> map_size() > 0
  end

  defp trigger_live_select_option_clicks(session, field, selected_values) do
    selectors = Map.get(field, :option_phx_click_selectors, %{})
    target = FormData.target_path(field.name)

    Enum.reduce_while(selected_values, {:ok, session, %{triggered: false, target: target, transition: nil}}, fn
      selected_value, acc ->
        trigger_live_select_option_click(selectors, target, field, selected_value, acc)
    end)
  end

  defp trigger_live_select_option_click(selectors, target, field, selected_value, {:ok, current_session, _change}) do
    case Map.get(selectors, selected_value) do
      selector when is_binary(selector) and selector != "" ->
        result =
          current_session.view
          |> element(scoped_selector(selector, Session.scope(current_session)))
          |> Phoenix.LiveViewTest.render_click(%{"value" => selected_value})

        case resolve_live_change_result(current_session, result, target) do
          {:ok, next_session, change} -> {:cont, {:ok, next_session, change}}
          {:error, failed_session, reason, details} -> {:halt, {:error, failed_session, reason, details}}
        end

      _ ->
        {:halt, {:error, current_session, select_option_click_contract_error(), %{field: field, value: selected_value}}}
    end
  end

  defp select_option_click_contract_error do
    "expected select option to have a valid `phx-click` attribute on options or to belong to a `form`"
  end

  defp live_choose_error(session, reason) do
    observed = %{
      action: :choose,
      path: session.current_path,
      transition: session_transition(session)
    }

    {:error, session, observed, reason}
  end

  defp do_live_fill_in(session, %{name: name} = field, value) when is_binary(name) and name != "" do
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
  end

  defp do_live_toggle_checkbox(session, field, checked?, op) do
    apply_live_checkbox_change(session, field, checked?, op)
  end

  defp live_action_timeout_ms(session, opts), do: Keyword.get(opts, :timeout, session.timeout_ms)

  defp timeout_for_driver(%{timeout_overridden?: true, timeout_ms: timeout_ms}, _driver), do: timeout_ms
  defp timeout_for_driver(_session, driver), do: SessionConfig.default_timeout_ms(driver)

  defp wait_for_live_form_field(session, expected, opts, op) do
    finder = fn refreshed ->
      refreshed.html
      |> LiveViewHTML.find_form_field(expected, opts, Session.scope(refreshed))
      |> resolve_live_form_field_actionability(op)
    end

    wait_for_live_actionable(session, live_action_timeout_ms(session, opts), finder)
  end

  defp toggle_checkbox_in_static_mode(session, expected, opts, checked?, op) do
    case Html.find_form_field(session.html, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
        value = FormData.toggled_checkbox_value(session, field, checked?)

        updated = %{
          session
          | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
        }

        observed = %{
          action: op,
          path: session.current_path,
          field: field,
          checked: checked?,
          transition: session_transition(session)
        }

        {:ok, update_session(updated, op, observed), observed}

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        static_checkbox_error(session, op, "matched field is not a checkbox")

      {:ok, _field} ->
        static_checkbox_error(session, op, "matched field does not include a name attribute")

      :error ->
        static_checkbox_error(session, op, "no form field matched locator")
    end
  end

  defp static_checkbox_error(session, op, reason) do
    observed = %{
      action: op,
      path: session.current_path,
      transition: session_transition(session)
    }

    {:error, session, observed, reason}
  end

  defp wait_for_live_submit_button(session, expected, opts) do
    finder = fn refreshed ->
      case LiveViewHTML.find_submit_button(refreshed.html, expected, opts, Session.scope(refreshed)) do
        {:ok, %{disabled: true}} -> {:retry, "matched field is disabled"}
        {:ok, button} -> {:ok, button}
        :error -> {:error, "no submit button matched locator"}
      end
    end

    wait_for_live_actionable(session, live_action_timeout_ms(session, opts), finder)
  end

  defp wait_for_live_clickable_button(session, expected, opts, kind) do
    finder = fn refreshed ->
      case find_clickable_button(refreshed, expected, opts, kind) do
        {:ok, %{disabled: true}} -> {:retry, "matched field is disabled"}
        {:ok, button} -> {:ok, button}
        :error -> {:error, "no button matched locator"}
      end
    end

    wait_for_live_actionable(session, live_action_timeout_ms(session, opts), finder)
  end

  defp wait_for_live_actionable(session, timeout_ms, finder) when is_function(finder, 1) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_wait_for_live_actionable(session, deadline, nil, finder)
  end

  defp do_wait_for_live_actionable(session, deadline, pending_reason, finder) when is_function(finder, 1) do
    refreshed = with_latest_html(session)

    case finder.(refreshed) do
      {:ok, candidate} ->
        {:ok, refreshed, candidate}

      {:retry, reason} ->
        if live_action_time_remaining?(deadline) do
          Process.sleep(25)
          do_wait_for_live_actionable(refreshed, deadline, reason, finder)
        else
          {:error, refreshed, reason}
        end

      {:error, reason} ->
        if pending_reason && live_action_retryable_reason?(reason) && live_action_time_remaining?(deadline) do
          Process.sleep(25)
          do_wait_for_live_actionable(refreshed, deadline, pending_reason, finder)
        else
          {:error, refreshed, pending_reason || reason}
        end
    end
  end

  defp live_action_time_remaining?(deadline) do
    System.monotonic_time(:millisecond) < deadline
  end

  defp live_action_retryable_reason?(reason) do
    reason in ["no form field matched locator", "no submit button matched locator", "no button matched locator"]
  end

  defp live_field_disabled_reason(%{input_disabled: true}, :select), do: "matched select field is disabled"
  defp live_field_disabled_reason(%{input_disabled: true}, _op), do: "matched field is disabled"
  defp live_field_disabled_reason(_field, _op), do: nil

  defp resolve_live_form_field_actionability({:ok, field}, op) do
    cond do
      live_form_field_named?(field) ->
        live_field_actionability(field, op)

      live_form_field_clickable_without_name?(field) ->
        live_field_actionability(field, op)

      true ->
        {:error, live_field_missing_name_error(op)}
    end
  end

  defp resolve_live_form_field_actionability(:error, op), do: {:error, live_field_not_found_error(op)}

  defp live_field_actionability(field, op) do
    cond do
      reason = live_field_type_error(op, field) ->
        {:error, reason}

      reason = live_field_disabled_reason(field, op) ->
        {:retry, reason}

      true ->
        {:ok, field}
    end
  end

  defp live_form_field_named?(%{name: name}) when is_binary(name), do: name != ""
  defp live_form_field_named?(_field), do: false

  defp live_form_field_clickable_without_name?(%{input_type: "checkbox"} = field) do
    checkbox_click_without_name_supported?(field)
  end

  defp live_form_field_clickable_without_name?(%{input_type: "radio"} = field) do
    radio_click_without_name_supported?(field)
  end

  defp live_form_field_clickable_without_name?(_field), do: false

  defp live_field_not_found_error(:upload), do: "no file input matched locator"
  defp live_field_not_found_error(_op), do: "no form field matched locator"

  defp live_field_missing_name_error(:upload), do: "matched upload field does not include a name attribute"
  defp live_field_missing_name_error(_op), do: "matched field does not include a name attribute"

  defp live_field_type_error(:select, %{input_type: "select"}), do: nil
  defp live_field_type_error(:select, _field), do: "matched field is not a select element"
  defp live_field_type_error(:choose, %{input_type: "radio"}), do: nil
  defp live_field_type_error(:choose, _field), do: "matched field is not a radio input"
  defp live_field_type_error(op, %{input_type: "checkbox"}) when op in [:check, :uncheck], do: nil
  defp live_field_type_error(op, _field) when op in [:check, :uncheck], do: "matched field is not a checkbox"
  defp live_field_type_error(:upload, %{input_type: "file"}), do: nil
  defp live_field_type_error(:upload, _field), do: "matched field is not a file input"
  defp live_field_type_error(_op, _field), do: nil

  defp apply_live_checkbox_change(session, field, checked?, op) do
    if checkbox_requires_phx_click?(field) and not field[:input_phx_click] do
      raise ArgumentError, checkbox_click_contract_error()
    end

    {change_result, _value} =
      if checkbox_click_without_name_supported?(field) do
        {trigger_live_checkbox_click(session, field, checked?), nil}
      else
        value = FormData.toggled_checkbox_value(session, field, checked?)
        form_data = FormData.put_form_value(session.form_data, field.form, field.form_selector, field.name, value)
        updated = %{session | form_data: form_data}

        change_result =
          if checkbox_requires_phx_click?(field) and field[:input_phx_click] do
            trigger_live_checkbox_click(updated, field, checked?)
          else
            maybe_trigger_live_change(updated, field)
          end

        {change_result, value}
      end

    case change_result do
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

  defp checkbox_requires_phx_click?(field) do
    field[:form] in [nil, ""] and field[:form_selector] in [nil, ""]
  end

  defp checkbox_click_without_name_supported?(field) do
    checkbox_requires_phx_click?(field) and field[:input_phx_click] and not present_name?(field[:name])
  end

  defp radio_requires_phx_click?(field) do
    field[:form] in [nil, ""] and field[:form_selector] in [nil, ""]
  end

  defp radio_click_without_name_supported?(field) do
    radio_requires_phx_click?(field) and field[:input_phx_click] and not present_name?(field[:name])
  end

  defp present_name?(name) when is_binary(name), do: name != ""
  defp present_name?(_name), do: false

  defp checkbox_click_contract_error do
    "expected checkbox input to have a valid `phx-click` attribute or belong to a `form`"
  end

  defp radio_click_contract_error do
    "expected radio input to have a valid `phx-click` attribute or belong to a `form` element"
  end

  defp maybe_trigger_live_change(%__MODULE__{} = session, field) do
    cond do
      field[:input_phx_change] ->
        trigger_input_phx_change(session, field)

      field[:form_phx_change] ->
        trigger_form_phx_change(session, field)

      field[:input_phx_click] ->
        trigger_input_phx_click(session, field)

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

  defp trigger_input_phx_click(session, field) do
    selector = field[:selector]

    if is_binary(selector) and selector != "" do
      result =
        session.view
        |> element(scoped_selector(selector, Session.scope(session)))
        |> render_click(%{})

      resolve_live_change_result(session, result, nil)
    else
      {:error, session, "live field click requires a resolvable field selector", %{field: field}}
    end
  end

  defp trigger_live_checkbox_click(session, field, checked?) do
    selector = field[:selector]

    if is_binary(selector) and selector != "" do
      payload = if(checked?, do: %{}, else: %{"value" => ""})

      result =
        session.view
        |> element(scoped_selector(selector, Session.scope(session)))
        |> render_click(payload)

      resolve_live_change_result(session, result, nil)
    else
      {:error, session, "live field click requires a resolvable field selector", %{field: field}}
    end
  end

  defp trigger_live_radio_click(session, field, value) do
    selector = field[:selector]

    if is_binary(selector) and selector != "" do
      result =
        session.view
        |> element(scoped_selector(selector, Session.scope(session)))
        |> render_click(%{"value" => value})

      resolve_live_change_result(session, result, nil)
    else
      {:error, session, "live field click requires a resolvable field selector", %{field: field}}
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
          timeout_ms: timeout_for_driver(session, :static),
          timeout_overridden?: session.timeout_overridden?,
          html: conn.resp_body || "",
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: session.last_result
        }
    end
  end

  defp maybe_store_follow_redirect_flash(%{conn: %Plug.Conn{} = conn} = session, flash) when is_map(flash) do
    %{session | conn: put_in(conn.private[:cerberus_follow_redirect_flash], flash)}
  end

  defp maybe_store_follow_redirect_flash(session, _flash), do: session

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
          timeout_ms: timeout_for_driver(session, :live),
          timeout_overridden?: session.timeout_overridden?,
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
          timeout_ms: timeout_for_driver(session, :static),
          timeout_overridden?: session.timeout_overridden?,
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
      timeout_ms: timeout_for_driver(session, :static),
      timeout_overridden?: session.timeout_overridden?,
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

  defp maybe_put_flash_cookie(conn, _endpoint, nil), do: conn

  defp maybe_put_flash_cookie(conn, endpoint, flash) do
    token =
      if is_map(flash) do
        Utils.sign_flash(endpoint, flash)
      else
        flash
      end

    Phoenix.ConnTest.put_req_cookie(conn, "__phoenix_flash__", token)
  end

  defp maybe_live_patch_path(nil, fallback_path), do: fallback_path

  defp maybe_live_patch_path(view, fallback_path) do
    case read_patch_path(view) do
      nil -> fallback_path
      path -> to_request_path(path, fallback_path)
    end
  end

  defp read_patch_path(%{proxy: {ref, topic, _pid}}) when is_reference(ref) and is_binary(topic) do
    receive do
      {^ref, {:patch, ^topic, %{to: path}}} when is_binary(path) -> path
    after
      0 -> nil
    end
  end

  defp read_patch_path(_view), do: nil

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
