defmodule Cerberus.Driver.Static do
  @moduledoc false

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.CandidateScope
  alias Cerberus.Driver.DownloadAssertion
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.LocatorOps
  alias Cerberus.Driver.SelectorFallback
  alias Cerberus.Driver.Static.FormData
  alias Cerberus.Html
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Phoenix.Conn
  alias Cerberus.Query
  alias Cerberus.Session
  alias Cerberus.Session.Config, as: SessionConfig
  alias Cerberus.Session.LastResult
  alias Cerberus.UploadFile
  alias ExUnit.AssertionError

  @type t :: %__MODULE__{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          timeout_ms: non_neg_integer(),
          timeout_overridden?: boolean(),
          document: LazyHTML.t() | nil,
          form_data: map(),
          scope: Session.scope_value(),
          current_path: String.t() | nil,
          last_result: Session.last_result()
        }

  defstruct endpoint: nil,
            conn: nil,
            timeout_ms: 0,
            timeout_overridden?: false,
            document: nil,
            form_data: %{active_form: nil, active_form_selector: nil, values: %{}},
            scope: nil,
            current_path: nil,
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    {timeout_ms, timeout_overridden?} = SessionConfig.timeout_from_opts!(opts, :static)

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
  def switch_tab(%__MODULE__{} = session, %__MODULE__{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    target_session
  end

  def switch_tab(%__MODULE__{} = session, %Live{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    target_session
  end

  def switch_tab(%__MODULE__{}, %Browser{}) do
    raise ArgumentError, "cannot switch non-browser tab to a browser session"
  end

  @impl true
  @spec close_tab(t()) :: t()
  def close_tab(%__MODULE__{} = session), do: session

  @impl true
  def open_browser(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
    document = snapshot_document(session)
    path = OpenBrowser.write_snapshot!(document, endpoint_url(session.endpoint), session.endpoint)
    _ = open_fun.(path)
    session
  end

  @impl true
  def render_html(%__MODULE__{} = session, callback) when is_function(callback, 1) do
    _ = callback.(snapshot_document(session))
    session
  end

  @impl true
  def unwrap(%__MODULE__{} = session, fun) when is_function(fun, 1) do
    session.conn
    |> Conn.ensure_conn()
    |> fun.()
    |> unwrap_conn_result(session, :static)
  end

  @impl true
  def within(%__MODULE__{} = session, %Locator{} = locator, callback) when is_function(callback, 1) do
    previous_scope = Session.scope(session)
    resolved_scope = resolve_within_scope!(session, locator, previous_scope)
    scoped_session = Session.with_scope(session, resolved_scope)
    callback_result = callback.(scoped_session)

    restore_scope!(callback_result, previous_scope)
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
        document = Html.parse!(html)

        %Live{
          endpoint: session.endpoint,
          conn: conn,
          timeout_ms: timeout_for_driver(session, :live),
          timeout_overridden?: session.timeout_overridden?,
          view: view,
          document: document,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: LastResult.new(:visit, %{path: current_path, transition: transition}, Live)
        }

      :error ->
        html = conn.resp_body || ""
        transition = transition(:static, :static, :visit, from_path, current_path)
        document = Html.parse!(html)

        %{
          session
          | conn: conn,
            document: document,
            current_path: current_path,
            last_result: LastResult.new(:visit, %{path: current_path, transition: transition}, __MODULE__)
        }
    end
  end

  @impl true
  def click(%__MODULE__{} = session, %Locator{} = locator, opts) do
    {expected, match_opts} = LocatorOps.click(locator, opts)
    kind = Keyword.get(match_opts, :kind, :any)

    case find_clickable_link(session, expected, match_opts, kind) do
      {:ok, link} ->
        click_static_link(session, link)

      :error ->
        case find_clickable_button(session, expected, match_opts, kind) do
          {:ok, %{disabled: true}} ->
            observed = %{
              action: :button,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, "matched field is disabled"}

          {:ok, button} ->
            maybe_submit_clicked_button(session, expected, match_opts, kind, button)

          :error ->
            observed = %{
              action: :click,
              path: session.current_path,
              candidate_values: click_candidate_values(session, match_opts, kind),
              texts: Html.texts(session.document, :any, Session.scope(session)),
              transition: session_transition(session)
            }

            {:error, session, observed, no_clickable_error(kind)}
        end
    end
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{} = locator, value, opts) do
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case Html.find_form_field(session.document, expected, match_opts, Session.scope(session)) do
      {:ok, %{input_disabled: true}} ->
        observed = %{action: :fill_in, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is disabled"}

      {:ok, %{name: name} = field} when is_binary(name) and name != "" ->
        updated =
          %{
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
        observed = %{action: :fill_in, path: session.current_path, transition: session_transition(session)}
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

  @impl true
  def select(%__MODULE__{} = session, %Locator{} = locator, opts) do
    {expected, match_opts} = LocatorOps.form(locator, opts)
    option = Keyword.fetch!(opts, :option)
    select_field(session, expected, match_opts, option, :select)
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{} = locator, opts) do
    {expected, match_opts} = LocatorOps.form(locator, opts)
    choose_radio(session, expected, match_opts)
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{} = locator, opts) do
    {expected, match_opts} = LocatorOps.form(locator, opts)
    toggle_checkbox(session, expected, match_opts, true, :check)
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{} = locator, opts) do
    {expected, match_opts} = LocatorOps.form(locator, opts)
    toggle_checkbox(session, expected, match_opts, false, :uncheck)
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{} = locator, path, opts) do
    {expected, match_opts} = LocatorOps.form(locator, opts)

    case Html.find_form_field(session.document, expected, match_opts, Session.scope(session)) do
      {:ok, %{input_disabled: true}} ->
        observed = %{action: :upload, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is disabled"}

      {:ok, %{name: name, input_type: "file"} = field} when is_binary(name) and name != "" ->
        file = UploadFile.read!(path)
        value = FormData.upload_value_for_update(session, field, file, path)

        updated =
          %{
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
        observed = %{action: :upload, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is not a file input"}

      {:ok, _field} ->
        observed = %{action: :upload, path: session.current_path, transition: session_transition(session)}
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
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{action: :upload, path: session.current_path, transition: session_transition(session)}
      {:error, session, observed, Exception.message(error)}
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{} = locator, opts) do
    {expected, match_opts} = LocatorOps.submit(locator, opts)

    case Html.find_submit_button(session.document, expected, match_opts, Session.scope(session)) do
      {:ok, %{disabled: true}} ->
        observed = %{action: :submit, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is disabled"}

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

  @impl true
  def submit_active_form(%__MODULE__{} = session, _opts) do
    case active_form_submit_button(session) do
      {:ok, button} ->
        do_submit(session, button)

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
      texts = Html.assertion_values(session.document, match_by, visible, Session.scope(session))
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
          {:ok, update_last_result(session, :assert_has, observed), observed}

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
      texts = Html.assertion_values(session.document, match_by, visible, Session.scope(session))
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
          {:ok, update_last_result(session, :refute_has, observed), observed}

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
    {field_expected, match_opts} = LocatorOps.form(locator, opts)
    op = value_assertion_op(mode)

    case Html.find_form_field(session.document, field_expected, match_opts, Session.scope(session)) do
      {:ok, field} ->
        value = current_field_value(session, field)
        matched? = value_matches?(value, expected)
        observed = value_assertion_observed(session, field, expected, value)

        if value_assertion_satisfied?(mode, matched?) do
          {:ok, update_last_result(session, op, observed), observed}
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
        {:ok, update_last_result(session, op, observed), observed}

      {:error, reason} ->
        {:error, session, observed, reason}
    end
  end

  defp locator_assertion_values(%__MODULE__{} = session, %Locator{} = locator, visible) do
    matched = Html.locator_assertion_values(session.document, locator, visible, Session.scope(session))

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
    DownloadAssertion.assert_from_conn!(session, filename)
  end

  @impl true
  def default_timeout_ms(%__MODULE__{} = session), do: session.timeout_ms

  @impl true
  def run_path_assertion(%__MODULE__{} = session, expected, opts, timeout, op) when op in [:assert_path, :refute_path] do
    driver_opts = Keyword.put(opts, :timeout, timeout)
    run_path_assertion_operation!(__MODULE__, session, expected, driver_opts, op)
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

  defp update_session(session, op, observed) do
    %{session | last_result: LastResult.new(op, observed, session)}
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

  defp update_last_result(%__MODULE__{} = session, op, observed) do
    %{session | last_result: LastResult.new(op, observed, session)}
  end

  defp update_last_result(%Live{} = session, op, observed) do
    %{session | last_result: LastResult.new(op, observed, session)}
  end

  defp find_clickable_link(_session, _expected, _opts, :button), do: :error

  defp find_clickable_link(session, expected, opts, _kind) do
    Html.find_link(session.document, expected, opts, Session.scope(session))
  end

  defp find_clickable_button(_session, _expected, _opts, :link), do: :error

  defp find_clickable_button(session, expected, opts, _kind) do
    Html.find_button(session.document, expected, opts, Session.scope(session))
  end

  defp click_button_error(_kind), do: "static driver does not support button clicks"

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
          Html.assertion_values(session.document, :text, :any, scope)

        {false, :link, :text} ->
          Html.assertion_values(session.document, :link, :any, scope)

        {false, :button, :text} ->
          Html.assertion_values(session.document, :button, :any, scope)

        {false, :any, :text} ->
          Html.assertion_values(session.document, :link, :any, scope) ++
            Html.assertion_values(session.document, :button, :any, scope)

        _ ->
          Html.assertion_values(session.document, match_by, :any, scope)
      end

    Enum.uniq(values)
  end

  defp field_candidate_values(session, match_opts) do
    match_by = Keyword.get(match_opts, :match_by, :label)
    Html.assertion_values(session.document, match_by, :any, Session.scope(session))
  end

  defp submit_candidate_values(session, match_opts) do
    match_by =
      case Keyword.get(match_opts, :match_by, :text) do
        :text -> :button
        other -> other
      end

    Html.assertion_values(session.document, match_by, :any, Session.scope(session))
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
    Html.form_defaults(session.document, selector, Session.scope(session))
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

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp maybe_submit_clicked_button(session, expected, match_opts, kind, button) do
    case click_static_data_method(session, button, :button) do
      :not_data_method ->
        case Html.find_submit_button(session.document, expected, match_opts, Session.scope(session)) do
          {:ok, submit_button} ->
            do_submit(session, submit_button)

          :error ->
            observed = %{
              action: :button,
              clicked: button.text,
              path: session.current_path,
              transition: session_transition(session)
            }

            {:error, session, observed, click_button_error(kind)}
        end

      result ->
        result
    end
  end

  defp click_static_link(session, link) do
    case click_static_data_method(session, link, :link) do
      :not_data_method ->
        click_static_link_via_href(session, link)

      result ->
        result
    end
  end

  defp click_static_link_via_href(session, %{href: href} = link) when is_binary(href) and href != "" do
    updated = visit(session, href, [])
    transition = transition(:static, driver_kind(updated), :click, session.current_path, Session.current_path(updated))

    observed = %{
      action: :link,
      path: Session.current_path(updated),
      clicked: link.text,
      texts: Html.texts(updated.document, :any, Session.scope(updated)),
      transition: transition
    }

    {:ok, update_last_result(updated, :click, observed), observed}
  end

  defp click_static_link_via_href(session, link) do
    observed = %{
      action: :link,
      path: session.current_path,
      clicked: link[:text] || "",
      transition: session_transition(session)
    }

    {:error, session, observed, "link does not define href"}
  end

  defp click_static_data_method(session, element, action) do
    with {:ok, normalized_method} <- static_data_method_action(element, action),
         {:ok, target} <- data_method_target_result(element) do
      do_click_static_data_method(session, element, action, normalized_method, target)
    else
      :not_data_method ->
        :not_data_method

      {:error, :missing_target} ->
        static_data_method_target_error(session, element, action)
    end
  end

  defp static_data_method_action(element, action) do
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

  defp static_data_method_target_error(session, element, action) do
    observed = %{
      action: action,
      clicked: element[:text] || "",
      path: session.current_path,
      transition: session_transition(session)
    }

    {:error, session, observed, "data-method element must define `data-to` or `href`"}
  end

  defp do_click_static_data_method(session, element, action, method, target) do
    case follow_form_request(session, method, target, %{}) do
      {:ok, updated, _transition} ->
        transition =
          transition(:static, driver_kind(updated), :click, session.current_path, Session.current_path(updated))

        observed = %{
          action: action,
          clicked: element[:text] || "",
          method: method,
          path: Session.current_path(updated),
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

  defp active_form_submit_button(session) do
    case FormData.active_form_selector(session.form_data) do
      selector when is_binary(selector) and selector != "" ->
        submit_scope = merge_submit_scope(Session.scope(session), selector)

        case Html.find_submit_button(
               session.document,
               ~r/.*/,
               [],
               submit_scope
             ) do
          {:ok, button} -> {:ok, button}
          :error -> {:error, "submit/1 could not find a submit button in the active form"}
        end

      _ ->
        {:error, "submit/1 requires an active form; call fill_in/select/choose/check/uncheck/upload first"}
    end
  end

  defp merge_submit_scope(scope, submit_selector) when is_binary(scope) and scope != "" do
    "#{scope} #{submit_selector}"
  end

  defp merge_submit_scope(_scope, submit_selector), do: submit_selector

  defp do_submit(session, button) do
    method = normalize_submit_method(button.method)
    form_selector = FormData.submit_form_selector(button)
    submitted_params = FormData.params_for_submit(session, button, form_selector)
    request_params = normalize_submit_request_params(method, submitted_params)

    case follow_form_request(session, method, button.action, request_params) do
      {:ok, updated, transition} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          method: method,
          path: Session.current_path(updated),
          params: request_params,
          transition: transition
        }

        cleared_form_data = FormData.clear_submitted_form(session.form_data, button.form, button.form_selector)
        {:ok, clear_submitted_session(updated, cleared_form_data, :submit, observed), observed}

      {:error, failed_session, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button.text,
          method: method,
          path: session.current_path,
          details: details,
          transition: session_transition(session)
        }

        {:error, failed_session, observed, reason}
    end
  end

  defp normalize_submit_request_params("get", params), do: params
  defp normalize_submit_request_params(_method, params), do: FormData.decode_query_params(params)

  defp follow_form_request(session, method, action, params) do
    request_path = submit_request_path(method, action, session.current_path, params)
    request_params = if method == "get", do: %{}, else: params

    conn =
      session.conn
      |> Conn.ensure_conn()
      |> then(&Conn.follow_request(session.endpoint, &1, method, request_path, request_params))

    updated = session_from_conn(session, conn, request_path)

    transition =
      transition(:static, driver_kind(updated), :submit, session.current_path, Session.current_path(updated))

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
        document = Html.parse!(html)

        %Live{
          endpoint: session.endpoint,
          conn: conn,
          timeout_ms: timeout_for_driver(session, :live),
          timeout_overridden?: session.timeout_overridden?,
          view: view,
          document: document,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: session.last_result
        }

      :error ->
        document = Html.parse!(conn.resp_body || "")

        %{
          session
          | conn: conn,
            document: document,
            current_path: current_path
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
          |> visit(redirect_path, [])

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

  defp build_unwrap_session_from_conn(session, conn, from_driver) do
    current_path = Conn.current_path(conn, session.current_path)

    case try_live(conn) do
      {:ok, view, html} ->
        unwrap_transition = transition(from_driver, :live, :unwrap, session.current_path, current_path)
        document = Html.parse!(html)

        %Live{
          endpoint: session.endpoint,
          conn: conn,
          view: view,
          document: document,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: LastResult.new(:unwrap, %{path: current_path, transition: unwrap_transition}, Live)
        }

      :error ->
        unwrap_transition = transition(from_driver, :static, :unwrap, session.current_path, current_path)
        document = Html.parse!(conn.resp_body || "")

        %__MODULE__{
          endpoint: session.endpoint,
          conn: conn,
          document: document,
          form_data: session.form_data,
          scope: session.scope,
          current_path: current_path,
          last_result: LastResult.new(:unwrap, %{path: current_path, transition: unwrap_transition}, __MODULE__)
        }
    end
  end

  defp static_seed_from_session(session, conn) do
    document = Html.parse!(conn.resp_body || "")

    %__MODULE__{
      endpoint: session.endpoint,
      conn: conn,
      document: document,
      form_data: session.form_data,
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

  defp normalize_submit_method(nil), do: "get"

  defp blank_to_nil(value) when is_binary(value), do: if(String.trim(value) == "", do: nil, else: value)
  defp blank_to_nil(_), do: nil

  defp data_method_target(element) do
    blank_to_nil(Map.get(element, :data_to)) || blank_to_nil(Map.get(element, :href))
  end

  defp timeout_for_driver(%{timeout_overridden?: true, timeout_ms: timeout_ms}, _driver), do: timeout_ms
  defp timeout_for_driver(_session, driver), do: SessionConfig.default_timeout_ms(driver)

  defp clear_submitted_session(%__MODULE__{} = session, form_data, op, observed) do
    %{
      session
      | form_data: form_data,
        last_result: LastResult.new(op, observed, session)
    }
  end

  defp clear_submitted_session(%Live{} = session, form_data, op, observed) do
    %{
      session
      | form_data: form_data,
        last_result: LastResult.new(op, observed, session)
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

  defp snapshot_document(%__MODULE__{document: %LazyHTML{} = document}), do: document

  defp snapshot_document(%__MODULE__{conn: %{resp_body: html}}) when is_binary(html), do: Html.parse!(html)

  defp snapshot_document(%__MODULE__{}), do: Html.parse!("")

  defp endpoint_url(endpoint) when is_atom(endpoint) do
    endpoint.url()
  rescue
    _ -> nil
  end

  defp resolve_within_scope!(session, locator, previous_scope) do
    case Html.find_scope_target(session_document!(session), locator, previous_scope) do
      {:ok, %{selector: selector}} when is_binary(selector) and selector != "" ->
        selector

      {:error, reason} ->
        raise AssertionError, message: "within/3 failed: #{reason}"
    end
  end

  defp session_document!(%{document: %LazyHTML{} = document}), do: document

  defp session_document!(_session), do: raise(ArgumentError, "within/3 requires a session with rendered document")

  defp restore_scope!(%{__struct__: _} = session, previous_scope) do
    Session.with_scope(session, previous_scope)
  end

  defp restore_scope!(_value, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp ensure_same_endpoint!(%{endpoint: endpoint}, %{endpoint: endpoint}), do: :ok

  defp ensure_same_endpoint!(_session, _target_session) do
    raise ArgumentError, "cannot switch tab across sessions with different endpoints"
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
    case Html.find_form_field(session.document, expected, opts, Session.scope(session)) do
      {:ok, %{input_disabled: true}} ->
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is disabled"}

      {:ok, %{name: name, input_type: "checkbox"} = field} when is_binary(name) and name != "" ->
        value = FormData.toggled_checkbox_value(session, field, checked?)

        updated =
          %{
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
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is not a checkbox"}

      {:ok, _field} ->
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp choose_radio(session, expected, opts) do
    case Html.find_form_field(session.document, expected, opts, Session.scope(session)) do
      {:ok, %{input_disabled: true}} ->
        observed = %{action: :choose, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is disabled"}

      {:ok, %{name: name, input_type: "radio"} = field} when is_binary(name) and name != "" ->
        value = field[:input_value] || "on"

        updated =
          %{
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
        observed = %{action: :choose, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is not a radio input"}

      {:ok, _field} ->
        observed = %{action: :choose, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: :choose, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "no form field matched locator"}
    end
  end

  defp select_field(session, expected, opts, option, op) do
    case Html.find_form_field(session.document, expected, opts, Session.scope(session)) do
      {:ok, %{name: name, input_type: "select"} = field} when is_binary(name) and name != "" ->
        case Html.select_values(session.document, field, option, opts, Session.scope(session)) do
          {:ok, %{values: values, multiple?: multiple?}} ->
            value = FormData.select_value_for_update(session, field, option, values, multiple?)

            updated =
              %{
                session
                | form_data: FormData.put_form_value(session.form_data, field.form, field.form_selector, name, value)
              }

            observed = %{
              action: op,
              path: session.current_path,
              field: field,
              option: option,
              value: value,
              transition: session_transition(session)
            }

            {:ok, update_session(updated, op, observed), observed}

          {:error, reason} ->
            observed = %{
              action: op,
              path: session.current_path,
              field: field,
              option: option,
              transition: session_transition(session)
            }

            {:error, session, observed, reason}
        end

      {:ok, %{name: name}} when is_binary(name) and name != "" ->
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field is not a select element"}

      {:ok, _field} ->
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
        {:error, session, observed, "matched field does not include a name attribute"}

      :error ->
        observed = %{action: op, path: session.current_path, transition: session_transition(session)}
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

  defp session_transition(%{last_result: %{transition: transition}}), do: transition
  defp session_transition(_session), do: nil

  defp driver_kind(%__MODULE__{}), do: :static
  defp driver_kind(%Live{}), do: :live
end
