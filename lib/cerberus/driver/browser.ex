defmodule Cerberus.Driver.Browser do
  @moduledoc false

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Query
  alias Cerberus.Session
  alias Cerberus.UploadFile

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @default_screenshot_full_page false
  @user_context_supervisor Cerberus.Driver.Browser.UserContextSupervisor
  @empty_browser_context_defaults %{viewport: nil, user_agent: nil, init_scripts: []}

  @type viewport :: %{width: pos_integer(), height: pos_integer()}
  @type browser_context_defaults :: %{
          viewport: viewport() | nil,
          user_agent: String.t() | nil,
          init_scripts: [String.t()]
        }

  @type t :: %__MODULE__{
          user_context_pid: pid(),
          tab_id: String.t(),
          browser_name: :chrome | :firefox,
          base_url: String.t(),
          assert_timeout_ms: non_neg_integer(),
          ready_timeout_ms: pos_integer(),
          ready_quiet_ms: pos_integer(),
          browser_context_defaults: browser_context_defaults(),
          sandbox_metadata: String.t() | nil,
          scope: String.t() | nil,
          current_path: String.t() | nil,
          multi_select_memory: %{optional(String.t()) => [String.t()]},
          last_result: Session.last_result()
        }

  defstruct user_context_pid: nil,
            tab_id: nil,
            browser_name: :chrome,
            base_url: nil,
            assert_timeout_ms: 0,
            ready_timeout_ms: @default_ready_timeout_ms,
            ready_quiet_ms: @default_ready_quiet_ms,
            browser_context_defaults: @empty_browser_context_defaults,
            sandbox_metadata: nil,
            scope: nil,
            current_path: nil,
            multi_select_memory: %{},
            last_result: nil

  @impl true
  def new_session(opts \\ []) do
    owner = self()
    context_defaults = browser_context_defaults(opts)
    browser_name = Runtime.browser_name(opts)

    start_opts =
      opts
      |> Keyword.put(:owner, owner)
      |> Keyword.put(:browser_name, browser_name)
      |> Keyword.put(:browser_context_defaults, context_defaults)

    {user_context_pid, base_url} =
      case start_user_context(start_opts) do
        {:ok, user_context_pid} ->
          {user_context_pid, UserContextProcess.base_url(user_context_pid)}

        {:error, reason} ->
          raise ArgumentError, "failed to initialize browser driver: #{inspect(reason)}"
      end

    maybe_configure_sandbox_metadata!(user_context_pid, opts)

    tab_id =
      case UserContextProcess.active_tab(user_context_pid) do
        value when is_binary(value) -> value
        _ -> raise ArgumentError, "failed to initialize browser driver: missing active tab"
      end

    %__MODULE__{
      user_context_pid: user_context_pid,
      tab_id: tab_id,
      browser_name: browser_name,
      base_url: base_url,
      assert_timeout_ms: Session.assert_timeout_from_opts!(opts, Session.live_browser_assert_timeout_default_ms()),
      ready_timeout_ms: ready_timeout_ms(opts),
      ready_quiet_ms: ready_quiet_ms(opts),
      browser_context_defaults: context_defaults,
      sandbox_metadata: Keyword.get(opts, :sandbox_metadata)
    }
  end

  @spec open_user(t()) :: t()
  def open_user(%__MODULE__{} = session) do
    opts = [
      browser_name: session.browser_name,
      assert_timeout_ms: session.assert_timeout_ms,
      ready_timeout_ms: session.ready_timeout_ms,
      ready_quiet_ms: session.ready_quiet_ms,
      browser_context_defaults: session.browser_context_defaults
    ]

    opts =
      case session.sandbox_metadata do
        metadata when is_binary(metadata) and metadata != "" ->
          Keyword.put(opts, :sandbox_metadata, metadata)

        _ ->
          opts
      end

    new_session(opts)
  end

  @spec open_tab(t()) :: t()
  def open_tab(%__MODULE__{} = session) do
    case UserContextProcess.open_tab(session.user_context_pid) do
      {:ok, tab_id} ->
        %{
          session
          | tab_id: tab_id,
            scope: nil,
            current_path: nil,
            last_result: nil
        }

      {:error, reason, details} ->
        raise ArgumentError, "failed to open browser tab: #{reason} (#{inspect(details)})"
    end
  end

  @spec switch_tab(t(), t()) :: t()
  def switch_tab(%__MODULE__{} = session, %__MODULE__{} = target_session) do
    if session.user_context_pid != target_session.user_context_pid do
      raise ArgumentError, "cannot switch tab across different browser users; use open_user/1 for isolation"
    end

    case UserContextProcess.switch_tab(session.user_context_pid, target_session.tab_id) do
      :ok ->
        target_session

      {:error, reason, details} ->
        raise ArgumentError, "failed to switch browser tab: #{reason} (#{inspect(details)})"
    end
  end

  @spec close_tab(t()) :: t()
  def close_tab(%__MODULE__{} = session) do
    case UserContextProcess.close_tab(session.user_context_pid, session.tab_id) do
      :ok ->
        next_tab_id = UserContextProcess.active_tab(session.user_context_pid)

        if is_binary(next_tab_id) do
          %{
            session
            | tab_id: next_tab_id,
              scope: nil,
              current_path: nil,
              last_result: nil
          }
        else
          raise ArgumentError, "failed to close browser tab: no active tab selected"
        end

      {:error, reason, details} ->
        raise ArgumentError, "failed to close browser tab: #{reason} (#{inspect(details)})"
    end
  end

  @impl true
  def open_browser(%__MODULE__{} = session, open_fun) when is_function(open_fun, 1) do
    state = state!(session)

    case eval_json(state, browser_html_expression()) do
      {:ok, payload} ->
        html = Map.get(payload, "html", "")
        url = Map.get(payload, "url")
        path = OpenBrowser.write_snapshot!(html, snapshot_base_url(state.base_url, url))
        _ = open_fun.(path)
        session

      {:error, reason, details} ->
        raise ArgumentError, "failed to collect browser HTML snapshot: #{reason} (#{inspect(details)})"
    end
  end

  @spec screenshot(t(), Options.screenshot_opts()) :: t()
  def screenshot(%__MODULE__{} = session, opts \\ []) when is_list(opts) do
    state = state!(session)
    path = screenshot_path(opts)
    full_page = screenshot_full_page(opts)

    case capture_screenshot(state.tab_id, full_page, bidi_opts(state)) do
      {:ok, %{"data" => data}} when is_binary(data) ->
        write_screenshot!(path, data)
        update_last_result(session, :screenshot, %{path: path, full_page: full_page})

      {:ok, payload} ->
        raise ArgumentError, "failed to capture browser screenshot: unexpected payload #{inspect(payload)}"

      {:error, reason, details} ->
        raise ArgumentError, "failed to capture browser screenshot: #{reason} (#{inspect(details)})"
    end
  end

  @doc false
  @spec refresh_path(t()) :: t()
  def refresh_path(%__MODULE__{} = session) do
    state = state!(session)

    case eval_json(state, current_path_expression()) do
      {:ok, %{"path" => path}} when is_binary(path) ->
        %{session | current_path: path}

      _ ->
        session
    end
  end

  @doc false
  @spec wait_for_assertion_signal(t(), non_neg_integer()) :: t()
  def wait_for_assertion_signal(%__MODULE__{} = session, timeout_ms) when is_integer(timeout_ms) and timeout_ms >= 0 do
    state = state!(session)

    if timeout_ms > 0 do
      quiet_ms = max(min(session.ready_quiet_ms, timeout_ms), 1)

      _ =
        UserContextProcess.await_ready(
          state.user_context_pid,
          [timeout_ms: timeout_ms, quiet_ms: quiet_ms],
          state.tab_id
        )
    end

    refresh_path(session)
  end

  @impl true
  def visit(%__MODULE__{} = session, path, _opts) do
    state = state!(session)
    url = to_absolute_url(state.base_url, path)

    case navigate_browser(state, url) do
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
  def click(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :click, fn ready_state ->
      case clickables(ready_state, selector) do
        {:ok, clickables_data} ->
          do_click(session, ready_state, clickables_data, expected, match_opts, selector)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect clickable elements: #{reason}"}
      end
    end)
  end

  @impl true
  def fill_in(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, value, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :fill_in, fn ready_state ->
      case form_fields(ready_state, selector) do
        {:ok, fields_data} ->
          do_fill_in(session, ready_state, fields_data, expected, value, match_opts, selector)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect form fields: #{reason}"}
      end
    end)
  end

  @impl true
  def select(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)
    option = Keyword.fetch!(opts, :option)

    with_driver_ready(session, state, :select, fn ready_state ->
      case form_fields(ready_state, selector) do
        {:ok, fields_data} ->
          do_select(session, ready_state, fields_data, expected, option, match_opts, selector)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect form fields: #{reason}"}
      end
    end)
  end

  @impl true
  def choose(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :choose, fn ready_state ->
      case form_fields(ready_state, selector) do
        {:ok, fields_data} ->
          do_choose_radio(session, ready_state, fields_data, expected, match_opts, selector)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect form fields: #{reason}"}
      end
    end)
  end

  @impl true
  def check(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :check, fn ready_state ->
      case form_fields(ready_state, selector) do
        {:ok, fields_data} ->
          do_toggle_checkbox(session, ready_state, fields_data, expected, match_opts, selector, true, :check)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect form fields: #{reason}"}
      end
    end)
  end

  @impl true
  def uncheck(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :uncheck, fn ready_state ->
      case form_fields(ready_state, selector) do
        {:ok, fields_data} ->
          do_toggle_checkbox(session, ready_state, fields_data, expected, match_opts, selector, false, :uncheck)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect form fields: #{reason}"}
      end
    end)
  end

  @impl true
  def upload(%__MODULE__{} = session, %Locator{kind: :label, value: expected} = locator, path, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :upload, fn ready_state ->
      case file_fields(ready_state, selector) do
        {:ok, fields_data} ->
          do_upload(session, ready_state, fields_data, expected, path, match_opts, selector)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect upload fields: #{reason}"}
      end
    end)
  end

  @impl true
  def submit(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    selector = Keyword.get(match_opts, :selector)

    with_driver_ready(session, state, :submit, fn ready_state ->
      case clickables(ready_state, selector) do
        {:ok, clickables_data} ->
          do_submit(session, ready_state, clickables_data, expected, match_opts, selector)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to inspect submit controls: #{reason}"}
      end
    end)
  end

  @impl true
  def assert_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    visible = visibility_filter(opts)

    with_driver_ready(session, state, :assert_has, fn ready_state ->
      case with_snapshot(ready_state) do
        {next_state, snapshot} ->
          assert_snapshot_result(session, next_state, snapshot, expected, visible, match_opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to collect browser text snapshot: #{reason}"}
      end
    end)
  end

  @impl true
  def refute_has(%__MODULE__{} = session, %Locator{kind: :text, value: expected} = locator, opts) do
    state = state!(session)
    match_opts = locator_match_opts(locator, opts)
    visible = visibility_filter(opts)

    with_driver_ready(session, state, :refute_has, fn ready_state ->
      case with_snapshot(ready_state) do
        {next_state, snapshot} ->
          refute_snapshot_result(session, next_state, snapshot, expected, visible, match_opts)

        {:error, reason, details} ->
          observed = %{path: ready_state.current_path, details: details}
          {:error, session, observed, "failed to collect browser text snapshot: #{reason}"}
      end
    end)
  end

  defp do_click(session, state, clickables_data, expected, opts, selector) do
    kind = Keyword.get(opts, :kind, :any)
    links = Map.get(clickables_data, "links", [])
    buttons = Map.get(clickables_data, "buttons", [])

    link =
      if kind == :button do
        nil
      else
        Enum.find(links, &Query.match_text?(&1["text"] || "", expected, opts))
      end

    if link == nil do
      button =
        if kind == :link do
          nil
        else
          Enum.find(buttons, &Query.match_text?(&1["text"] || "", expected, opts))
        end

      if button == nil do
        observed = %{action: :click, path: state.current_path, clickables: clickables_data}
        {:error, session, observed, no_clickable_error(kind)}
      else
        click_button(session, state, button, selector)
      end
    else
      click_link(session, state, link)
    end
  end

  defp do_submit(session, state, clickables_data, expected, opts, selector) do
    buttons =
      clickables_data
      |> Map.get("buttons", [])
      |> Enum.filter(&submit_control?/1)

    case find_matching_by_text(buttons, expected, opts) do
      nil ->
        observed = %{action: :submit, path: state.current_path, clickables: clickables_data}
        {:error, session, observed, "no submit button matched locator"}

      button ->
        submit_button(session, state, button, selector)
    end
  end

  defp do_fill_in(session, state, fields_data, expected, value, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_by_label(fields, expected, opts) do
      nil ->
        observed = %{action: :fill_in, path: state.current_path, fields: fields_data}
        {:error, session, observed, "no form field matched locator"}

      field ->
        fill_field(session, state, field, value, selector)
    end
  end

  defp do_select(session, state, fields_data, expected, option, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_by_label(fields, expected, opts) do
      nil ->
        observed = %{action: :select, path: state.current_path, fields: fields_data, option: option}
        {:error, session, observed, "no form field matched locator"}

      field ->
        cond do
          not select_field?(field) ->
            observed = %{action: :select, path: state.current_path, field: field, option: option}
            {:error, session, observed, "matched field is not a select element"}

          field_disabled?(field) ->
            observed = %{action: :select, path: state.current_path, field: field, option: option}
            {:error, session, observed, "matched select field is disabled"}

          true ->
            preserve_existing = select_field_multiple?(field) and not is_list(option)
            exact_option = Keyword.get(opts, :exact_option, true)
            select_field_option(session, state, field, option, exact_option, preserve_existing, selector)
        end
    end
  end

  defp do_choose_radio(session, state, fields_data, expected, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_by_label(fields, expected, opts) do
      nil ->
        observed = %{action: :choose, path: state.current_path, fields: fields_data}
        {:error, session, observed, "no form field matched locator"}

      field ->
        cond do
          not radio_field?(field) ->
            observed = %{action: :choose, path: state.current_path, field: field}
            {:error, session, observed, "matched field is not a radio input"}

          field_disabled?(field) ->
            observed = %{action: :choose, path: state.current_path, field: field}
            {:error, session, observed, "matched field is disabled"}

          true ->
            choose_radio_field(session, state, field, selector)
        end
    end
  end

  defp do_upload(session, state, fields_data, expected, path, opts, selector) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_by_label(fields, expected, opts) do
      nil ->
        observed = %{action: :upload, path: state.current_path, fields: fields_data, file_path: path}
        {:error, session, observed, "no file input matched locator"}

      field ->
        upload_field(session, state, field, path, selector)
    end
  end

  defp do_toggle_checkbox(session, state, fields_data, expected, opts, selector, checked?, op) do
    fields = Map.get(fields_data, "fields", [])

    case find_matching_by_label(fields, expected, opts) do
      nil ->
        observed = %{action: op, path: state.current_path, fields: fields_data}
        {:error, session, observed, "no form field matched locator"}

      field ->
        if checkbox_field?(field) do
          toggle_checkbox_field(session, state, field, checked?, selector, op)
        else
          observed = %{action: op, path: state.current_path, field: field}
          {:error, session, observed, "matched field is not a checkbox"}
        end
    end
  end

  defp upload_field(session, state, field, path, selector) do
    file = UploadFile.read!(path)
    index = field["index"] || 0

    expression =
      upload_field_expression(
        index,
        file.file_name,
        file.mime_type,
        file.last_modified_unix_ms,
        file.content,
        Session.scope(state),
        selector
      )

    case eval_json(state, expression) do
      {:ok, result} ->
        upload_field_result(session, state, field, file.file_name, result)

      {:error, reason, details} ->
        observed = %{action: :upload, path: state.current_path, field: field, file_path: path, details: details}
        {:error, session, observed, "browser upload failed: #{reason}"}
    end
  rescue
    error in [ArgumentError, File.Error] ->
      observed = %{action: :upload, path: state.current_path, field: field, file_path: path}
      {:error, session, observed, Exception.message(error)}
  end

  defp upload_field_result(session, state, field, file_name, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        case snapshot_with_retry(state) do
          {next_state, snapshot} ->
            observed = %{
              action: :upload,
              path: snapshot.path,
              title: snapshot.title,
              field: field,
              file_name: file_name,
              readiness: readiness
            }

            {:ok, update_session(session, next_state, :upload, observed), observed}

          {:error, reason, details} ->
            observed = %{
              action: :upload,
              path: Map.get(result, "path", state.current_path),
              field: field,
              file_name: file_name,
              readiness: readiness,
              details: details
            }

            {:error, session, observed, "failed to inspect page after upload: #{reason}"}
        end

      {:error, reason, readiness} ->
        observed = %{
          action: :upload,
          path: state.current_path,
          field: field,
          file_name: file_name,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp upload_field_result(session, state, field, file_name, result) do
    reason = Map.get(result, "reason", "upload_failed")
    observed = %{action: :upload, path: state.current_path, field: field, file_name: file_name, result: result}
    {:error, session, observed, "browser upload failed: #{reason}"}
  end

  defp click_link(session, state, link) do
    url = link["resolvedHref"] || link["href"] || ""

    if url == "" do
      observed = %{action: :link, path: state.current_path, clicked: link["text"], link: link}
      {:error, session, observed, "matched link has no href"}
    else
      navigate_link(session, state, link, url)
    end
  end

  defp submit_button(session, state, button, selector) do
    index = button["index"] || 0
    expression = button_click_expression(index, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, %{"ok" => true}} ->
        submit_after_eval(session, state, button)

      {:ok, result} ->
        reason = Map.get(result, "reason", "submit_target_failed")
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, result: result}
        {:error, session, observed, "browser submit failed: #{reason}"}

      {:error, reason, details} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser submit failed: #{reason}"}
    end
  end

  defp submit_after_eval(session, state, button) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        submit_snapshot_result(session, state, button, readiness)

      {:error, reason, readiness} ->
        observed = %{action: :submit, clicked: button["text"], path: state.current_path, readiness: readiness}
        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp submit_snapshot_result(session, state, button, readiness) do
    case snapshot_with_retry(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :submit,
          clicked: button["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden,
          readiness: readiness
        }

        {:ok, update_session(session, next_state, :submit, observed), observed}

      {:error, reason, details} ->
        observed = %{
          action: :submit,
          clicked: button["text"],
          path: state.current_path,
          details: details,
          readiness: readiness
        }

        {:error, session, observed, "failed to inspect page after submit: #{reason}"}
    end
  end

  defp fill_field(session, state, field, value, selector) do
    index = field["index"] || 0
    expression = field_set_expression(index, value, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, result} ->
        fill_field_result(session, state, field, value, result)

      {:error, reason, details} ->
        observed = %{action: :fill_in, path: state.current_path, field: field, details: details}
        {:error, session, observed, "browser field fill failed: #{reason}"}
    end
  end

  defp toggle_checkbox_field(session, state, field, checked?, selector, op) do
    index = field["index"] || 0
    expression = checkbox_set_expression(index, checked?, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, result} ->
        toggle_checkbox_result(session, state, field, checked?, op, result)

      {:error, reason, details} ->
        observed = %{action: op, path: state.current_path, field: field, checked: checked?, details: details}
        {:error, session, observed, "browser checkbox toggle failed: #{reason}"}
    end
  end

  defp select_field_option(session, state, field, option, exact_option, preserve_existing, selector) do
    index = field["index"] || 0
    options = List.wrap(option)
    remembered_values = remembered_multi_select_values(session, field)

    expression =
      select_set_expression(
        index,
        options,
        exact_option,
        preserve_existing,
        remembered_values,
        Session.scope(state),
        selector
      )

    case eval_json(state, expression) do
      {:ok, result} ->
        select_field_result(session, state, field, option, result)

      {:error, reason, details} ->
        observed = %{action: :select, path: state.current_path, field: field, option: option, details: details}
        {:error, session, observed, "browser select failed: #{reason}"}
    end
  end

  defp choose_radio_field(session, state, field, selector) do
    index = field["index"] || 0
    expression = radio_set_expression(index, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, result} ->
        choose_radio_result(session, state, field, result)

      {:error, reason, details} ->
        observed = %{action: :choose, path: state.current_path, field: field, details: details}
        {:error, session, observed, "browser choose failed: #{reason}"}
    end
  end

  defp fill_field_result(session, state, field, value, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: :fill_in,
          path: Map.get(result, "path", state.current_path),
          field: field,
          value: value,
          readiness: readiness
        }

        {:ok, update_last_result(session, :fill_in, observed), observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :fill_in,
          path: state.current_path,
          field: field,
          value: value,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp fill_field_result(session, state, field, _value, result) do
    reason = Map.get(result, "reason", "field_fill_failed")
    observed = %{action: :fill_in, path: state.current_path, field: field, result: result}
    {:error, session, observed, "browser field fill failed: #{reason}"}
  end

  defp toggle_checkbox_result(session, state, field, checked?, op, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: op,
          path: Map.get(result, "path", state.current_path),
          field: field,
          checked: checked?,
          readiness: readiness
        }

        {:ok, update_last_result(session, op, observed), observed}

      {:error, reason, readiness} ->
        observed = %{
          action: op,
          path: state.current_path,
          field: field,
          checked: checked?,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp toggle_checkbox_result(session, state, field, checked?, op, result) do
    reason = Map.get(result, "reason", "checkbox_toggle_failed")
    observed = %{action: op, path: state.current_path, field: field, checked: checked?, result: result}
    {:error, session, observed, "browser checkbox toggle failed: #{reason}"}
  end

  defp select_field_result(session, state, field, option, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        session = remember_multi_select_value(session, field, Map.get(result, "value"))

        observed = %{
          action: :select,
          path: Map.get(result, "path", state.current_path),
          field: field,
          option: option,
          value: Map.get(result, "value"),
          readiness: readiness
        }

        {:ok, update_last_result(session, :select, observed), observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :select,
          path: state.current_path,
          field: field,
          option: option,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp select_field_result(session, state, field, option, result) do
    reason = Map.get(result, "reason", "select_failed")
    observed = %{action: :select, path: state.current_path, field: field, option: option, result: result}
    {:error, session, observed, "browser select failed: #{reason}"}
  end

  defp choose_radio_result(session, state, field, %{"ok" => true} = result) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        observed = %{
          action: :choose,
          path: Map.get(result, "path", state.current_path),
          field: field,
          value: Map.get(result, "value"),
          readiness: readiness
        }

        {:ok, update_last_result(session, :choose, observed), observed}

      {:error, reason, readiness} ->
        observed = %{
          action: :choose,
          path: state.current_path,
          field: field,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp choose_radio_result(session, state, field, result) do
    reason = Map.get(result, "reason", "choose_failed")
    observed = %{action: :choose, path: state.current_path, field: field, result: result}
    {:error, session, observed, "browser choose failed: #{reason}"}
  end

  defp navigate_link(session, state, link, url) do
    case navigate_browser(state, url) do
      {:ok, _} ->
        link_snapshot_result(session, state, link)

      {:error, reason, details} ->
        observed = %{action: :link, clicked: link["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser link navigation failed: #{reason}"}
    end
  end

  defp link_snapshot_result(session, state, link) do
    case with_snapshot(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :link,
          clicked: link["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden
        }

        {:ok, update_session(session, next_state, :click, observed), observed}

      {:error, reason, details} ->
        observed = %{action: :link, clicked: link["text"], path: state.current_path, details: details}
        {:error, session, observed, "failed to inspect page after link click: #{reason}"}
    end
  end

  defp find_matching_by_text(items, expected, opts) do
    Enum.find(items, &Query.match_text?(&1["text"] || "", expected, opts))
  end

  defp find_matching_by_label(items, expected, opts) do
    Enum.find(items, &Query.match_text?(&1["label"] || "", expected, opts))
  end

  defp submit_control?(button) do
    type = (button["type"] || "submit") |> to_string() |> String.downcase()
    type in ["submit", ""]
  end

  defp checkbox_field?(field) do
    (field["type"] || "") |> to_string() |> String.downcase() == "checkbox"
  end

  defp radio_field?(field) do
    (field["type"] || "") |> to_string() |> String.downcase() == "radio"
  end

  defp select_field?(field) do
    (field["tag"] || "") |> to_string() |> String.downcase() == "select"
  end

  defp select_field_multiple?(field) do
    field["multiple"] == true
  end

  defp field_disabled?(field) do
    field["disabled"] == true
  end

  defp click_button(session, state, button, selector) do
    index = button["index"] || 0
    expression = button_click_expression(index, Session.scope(state), selector)

    case eval_json(state, expression) do
      {:ok, _result} ->
        click_button_after_eval(session, state, button)

      {:error, reason, details} ->
        observed = %{action: :button, clicked: button["text"], path: state.current_path, details: details}
        {:error, session, observed, "browser button click failed: #{reason}"}
    end
  end

  defp clickables(state, selector) do
    eval_json(state, clickables_expression(Session.scope(state), selector))
  end

  defp form_fields(state, selector) do
    eval_json(state, form_fields_expression(Session.scope(state), selector))
  end

  defp file_fields(state, selector) do
    eval_json(state, file_fields_expression(Session.scope(state), selector))
  end

  defp with_snapshot(state) do
    case eval_json(state, snapshot_expression(Session.scope(state))) do
      {:ok, snapshot} ->
        snapshot = %{
          path: snapshot["path"],
          title: snapshot["title"] || "",
          visible: snapshot["visible"] || [],
          hidden: snapshot["hidden"] || []
        }

        {%{state | current_path: snapshot.path}, snapshot}

      {:error, reason, details} ->
        {:error, reason, details}
    end
  end

  defp navigate_browser(state, url) do
    UserContextProcess.navigate(state.user_context_pid, url, state.tab_id)
  end

  defp eval_json(state, expression) do
    with {:ok, result} <- UserContextProcess.evaluate(state.user_context_pid, expression, state.tab_id),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  defp decode_remote_json(%{"result" => %{"type" => "string", "value" => payload}}) when is_binary(payload) do
    case JSON.decode(payload) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "invalid json payload from browser: #{inspect(reason)}"}
    end
  end

  defp decode_remote_json(result) do
    {:error, "unexpected script.evaluate result: #{inspect(result)}"}
  end

  defp with_driver_ready(session, state, action, on_ready) when is_function(on_ready, 1) do
    case await_driver_ready(state) do
      {:ok, _readiness} ->
        on_ready.(state)

      {:error, reason, readiness} ->
        observed = %{
          action: action,
          path: state.current_path,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp await_driver_ready(state) do
    opts = [timeout_ms: state.ready_timeout_ms, quiet_ms: state.ready_quiet_ms]

    case UserContextProcess.await_ready(state.user_context_pid, opts, state.tab_id) do
      {:ok, readiness} ->
        {:ok, readiness}

      {:error, reason, details} ->
        normalize_await_ready_error(state, reason, details)
    end
  end

  defp readiness_error(reason, readiness) do
    awaited = Map.get(readiness, "awaited", [])
    awaited_label = if is_list(awaited), do: Enum.join(awaited, ", "), else: inspect(awaited)
    last_signal = Map.get(readiness, "lastSignal", "unknown")
    live_state = Map.get(readiness, "lastLiveState", "unknown")

    "browser readiness failed: #{reason} (awaited: #{awaited_label}; last_signal: #{last_signal}; live_state: #{live_state})"
  end

  defp navigation_transition_error?(reason, details) do
    combined = "#{reason} #{inspect(details)}"

    String.contains?(combined, "Inspected target navigated or closed") or
      String.contains?(combined, "Cannot find context with specified id") or
      String.contains?(combined, "execution contexts cleared")
  end

  defp readiness_payload?(payload) when is_map(payload) do
    Map.has_key?(payload, "awaited") or Map.has_key?(payload, "lastSignal")
  end

  defp assert_snapshot_result(session, next_state, snapshot, expected, visible, opts) do
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
      {:error, session, observed, "expected text not found"}
    else
      {:ok, update_session(session, next_state, :assert_has, observed), observed}
    end
  end

  defp refute_snapshot_result(session, next_state, snapshot, expected, visible, opts) do
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
      {:ok, update_session(session, next_state, :refute_has, observed), observed}
    else
      {:error, session, observed, "unexpected matching text found"}
    end
  end

  defp click_button_after_eval(session, state, button) do
    case await_driver_ready(state) do
      {:ok, readiness} ->
        click_button_snapshot_result(session, state, button, readiness)

      {:error, reason, readiness} ->
        observed = %{
          action: :button,
          clicked: button["text"],
          path: state.current_path,
          readiness: readiness
        }

        {:error, session, observed, readiness_error(reason, readiness)}
    end
  end

  defp click_button_snapshot_result(session, state, button, readiness) do
    case snapshot_with_retry(state) do
      {next_state, snapshot} ->
        observed = %{
          action: :button,
          clicked: button["text"],
          path: snapshot.path,
          title: snapshot.title,
          texts: snapshot.visible ++ snapshot.hidden,
          readiness: readiness
        }

        {:ok, update_session(session, next_state, :click, observed), observed}

      {:error, reason, details} ->
        observed = %{
          action: :button,
          clicked: button["text"],
          path: state.current_path,
          details: details,
          readiness: readiness
        }

        {:error, session, observed, "failed to inspect page after button click: #{reason}"}
    end
  end

  defp normalize_await_ready_error(state, reason, details) do
    if navigation_transition_error?(reason, details) do
      {:ok, navigation_transition_readiness(details)}
    else
      if readiness_payload?(details) do
        {:error, reason, details}
      else
        {:error, reason, merge_last_readiness(state, details)}
      end
    end
  end

  defp navigation_transition_readiness(details) do
    %{
      "ok" => true,
      "reason" => "navigation-transition",
      "awaited" => ["navigation-complete"],
      "lastSignal" => "bidi-navigation-transition",
      "lastLiveState" => "unknown",
      "details" => details
    }
  end

  defp merge_last_readiness(state, details) do
    readiness =
      case UserContextProcess.last_readiness(state.user_context_pid, state.tab_id) do
        %{} = last when map_size(last) > 0 -> last
        _ -> %{}
      end

    Map.put_new(readiness, "details", details)
  end

  defp snapshot_with_retry(state, attempts \\ 6, delay_ms \\ 50)

  defp snapshot_with_retry(state, attempts, _delay_ms) when attempts <= 0 do
    with_snapshot(state)
  end

  defp snapshot_with_retry(state, attempts, delay_ms) do
    case with_snapshot(state) do
      {:error, reason, details} = error ->
        if navigation_transition_error?(reason, details) do
          Process.sleep(delay_ms)
          snapshot_with_retry(state, attempts - 1, delay_ms)
        else
          error
        end

      success ->
        success
    end
  end

  defp select_texts(snapshot, true), do: snapshot.visible
  defp select_texts(snapshot, false), do: snapshot.hidden
  defp select_texts(snapshot, :any), do: snapshot.visible ++ snapshot.hidden

  defp state!(%__MODULE__{user_context_pid: user_context_pid, tab_id: tab_id} = state)
       when is_pid(user_context_pid) and is_binary(tab_id) do
    state
  end

  defp state!(_), do: raise(ArgumentError, "browser driver state is not initialized")

  defp update_session(%__MODULE__{} = session, %{} = state, op, observed) do
    %{
      session
      | user_context_pid: state.user_context_pid,
        tab_id: state.tab_id,
        browser_name: state.browser_name,
        base_url: state.base_url,
        assert_timeout_ms: state.assert_timeout_ms,
        ready_timeout_ms: state.ready_timeout_ms,
        ready_quiet_ms: state.ready_quiet_ms,
        browser_context_defaults: state.browser_context_defaults,
        sandbox_metadata: state.sandbox_metadata,
        scope: session.scope,
        current_path: state.current_path,
        multi_select_memory: session.multi_select_memory,
        last_result: %{op: op, observed: observed}
    }
  end

  defp update_last_result(%__MODULE__{} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp remembered_multi_select_values(%__MODULE__{} = session, field) do
    case select_field_memory_key(session, field) do
      nil -> []
      key -> Map.get(session.multi_select_memory, key, [])
    end
  end

  defp remember_multi_select_value(%__MODULE__{} = session, field, value) do
    if select_field_multiple?(field) do
      case select_field_memory_key(session, field) do
        nil ->
          session

        key ->
          values =
            value
            |> List.wrap()
            |> Enum.map(&to_string/1)

          %{session | multi_select_memory: Map.put(session.multi_select_memory, key, values)}
      end
    else
      session
    end
  end

  defp select_field_memory_key(%__MODULE__{} = session, field) when is_map(field) do
    path = session.current_path || ""
    key = field["id"] || field["name"]

    if is_binary(key) and key != "" do
      "#{path}::#{key}"
    end
  end

  defp no_clickable_error(:link), do: "no link matched locator"
  defp no_clickable_error(:button), do: "no button matched locator"
  defp no_clickable_error(_kind), do: "no clickable element matched locator"

  defp locator_match_opts(%Locator{opts: locator_opts}, opts) do
    Keyword.merge(locator_opts, opts)
  end

  defp to_absolute_url(base_url, path_or_url) do
    uri = URI.parse(path_or_url)

    if is_binary(uri.scheme) do
      path_or_url
    else
      base_uri = URI.parse(base_url)
      base_uri |> URI.merge(path_or_url) |> to_string()
    end
  end

  defp browser_html_expression do
    """
    (() => {
      const doc = document.documentElement;
      const html = doc ? doc.outerHTML : "";
      const doctype = document.doctype ? `<!DOCTYPE ${document.doctype.name}>` : "<!DOCTYPE html>";
      return JSON.stringify({ html: doctype + html, url: window.location.href });
    })()
    """
  end

  defp snapshot_base_url(default_base_url, url) when is_binary(url) do
    uri = URI.parse(url)

    if is_binary(uri.scheme) and is_binary(uri.host) do
      port_suffix =
        case uri.port do
          nil -> ""
          80 when uri.scheme == "http" -> ""
          443 when uri.scheme == "https" -> ""
          port -> ":" <> Integer.to_string(port)
        end

      uri.scheme <> "://" <> uri.host <> port_suffix
    else
      default_base_url
    end
  rescue
    _ -> default_base_url
  end

  defp snapshot_base_url(default_base_url, _url), do: default_base_url

  defp capture_screenshot(context_id, full_page, bidi_opts) do
    params = maybe_full_page_origin(%{"context" => context_id}, full_page)

    BiDi.command("browsingContext.captureScreenshot", params, bidi_opts)
  end

  defp bidi_opts(%{browser_name: browser_name}), do: [browser_name: browser_name]

  defp maybe_full_page_origin(params, true), do: Map.put(params, "origin", "document")
  defp maybe_full_page_origin(params, _full_page), do: params

  defp write_screenshot!(path, encoded_data) when is_binary(path) and is_binary(encoded_data) do
    File.mkdir_p!(Path.dirname(path))

    case Base.decode64(encoded_data) do
      {:ok, data} ->
        File.write!(path, data)

      :error ->
        raise ArgumentError, "failed to decode browser screenshot payload"
    end
  end

  defp default_screenshot_path(browser_opts) do
    artifact_dir =
      browser_opts
      |> Keyword.get(:screenshot_artifact_dir)
      |> normalize_non_empty_string(System.tmp_dir!())

    Path.join([artifact_dir, "cerberus-screenshot#{System.unique_integer([:monotonic])}.png"])
  end

  @doc false
  @spec screenshot_path(keyword()) :: String.t()
  def screenshot_path(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    case Keyword.get(opts, :path) do
      path when is_binary(path) -> path
      nil -> configured_screenshot_path(browser_opts) || default_screenshot_path(browser_opts)
      path -> path
    end
  end

  @doc false
  @spec screenshot_full_page(keyword()) :: boolean()
  def screenshot_full_page(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    opts
    |> Keyword.get(:full_page, browser_opts[:screenshot_full_page])
    |> normalize_boolean(@default_screenshot_full_page)
  end

  defp start_user_context(opts) do
    case Process.whereis(@user_context_supervisor) do
      nil ->
        UserContextProcess.start_link(opts)

      supervisor_pid ->
        DynamicSupervisor.start_child(supervisor_pid, {UserContextProcess, opts})
    end
  end

  @doc false
  @spec browser_context_defaults(keyword()) :: browser_context_defaults()
  def browser_context_defaults(opts) when is_list(opts) do
    case Keyword.get(opts, :browser_context_defaults) do
      %{} = defaults ->
        normalize_browser_context_defaults!(defaults)

      nil ->
        browser_opts = merged_browser_opts(opts)

        %{
          viewport: normalize_viewport(opt_value(opts, browser_opts, :viewport)),
          user_agent: normalize_user_agent(opt_value(opts, browser_opts, :user_agent)),
          init_scripts:
            normalize_init_scripts(
              opt_value(opts, browser_opts, :init_scripts),
              opt_value(opts, browser_opts, :init_script)
            )
        }

      other ->
        raise ArgumentError, ":browser_context_defaults must be a map, got: #{inspect(other)}"
    end
  end

  defp maybe_configure_sandbox_metadata!(user_context_pid, opts) do
    case Keyword.get(opts, :sandbox_metadata) do
      nil ->
        :ok

      metadata when is_binary(metadata) ->
        if String.trim(metadata) == "" do
          raise ArgumentError, ":sandbox_metadata must be a non-empty string"
        end

        case UserContextProcess.set_user_agent(user_context_pid, metadata) do
          :ok ->
            :ok

          {:error, reason, details} ->
            raise ArgumentError,
                  "failed to configure browser sandbox metadata: #{reason} (#{inspect(details)})"
        end

      other ->
        raise ArgumentError, "expected :sandbox_metadata option to be a string, got: #{inspect(other)}"
    end
  end

  @doc false
  @spec ready_timeout_ms(keyword()) :: pos_integer()
  def ready_timeout_ms(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    opts
    |> Keyword.get(:ready_timeout_ms, browser_opts[:ready_timeout_ms])
    |> normalize_positive_integer(@default_ready_timeout_ms)
  end

  defp ready_quiet_ms(opts) do
    browser_opts = merged_browser_opts(opts)

    opts
    |> Keyword.get(:ready_quiet_ms, browser_opts[:ready_quiet_ms])
    |> normalize_positive_integer(@default_ready_quiet_ms)
  end

  defp visibility_filter(opts) do
    case Keyword.get(opts, :visible, true) do
      :any -> :any
      false -> false
      _ -> true
    end
  end

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp normalize_boolean(value, _default) when is_boolean(value), do: value
  defp normalize_boolean(_value, default), do: default

  defp normalize_non_empty_string(value, default) when is_binary(value) do
    if byte_size(String.trim(value)) > 0, do: value, else: default
  end

  defp normalize_non_empty_string(_value, default), do: default

  defp configured_screenshot_path(browser_opts) do
    case Keyword.get(browser_opts, :screenshot_path) do
      path when is_binary(path) ->
        if byte_size(String.trim(path)) > 0, do: path

      _ ->
        nil
    end
  end

  defp normalize_browser_context_defaults!(defaults) when is_map(defaults) do
    %{
      viewport: normalize_viewport(Map.get(defaults, :viewport)),
      user_agent: normalize_user_agent(Map.get(defaults, :user_agent)),
      init_scripts: normalize_init_scripts(Map.get(defaults, :init_scripts), nil)
    }
  end

  defp merged_browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp opt_value(opts, browser_opts, key) do
    if Keyword.has_key?(opts, key), do: Keyword.get(opts, key), else: Keyword.get(browser_opts, key)
  end

  defp normalize_viewport(nil), do: nil

  defp normalize_viewport({width, height}) when is_integer(width) and is_integer(height) do
    viewport_dimensions!(width, height)
  end

  defp normalize_viewport(%{width: width, height: height}) when is_integer(width) and is_integer(height) do
    viewport_dimensions!(width, height)
  end

  defp normalize_viewport(viewport) when is_list(viewport) do
    width = Keyword.get(viewport, :width)
    height = Keyword.get(viewport, :height)

    if is_integer(width) and is_integer(height) do
      viewport_dimensions!(width, height)
    else
      raise ArgumentError,
            ":viewport must include integer :width and :height values, got: #{inspect(viewport)}"
    end
  end

  defp normalize_viewport(viewport) do
    raise ArgumentError, ":viewport must be nil, {width, height}, map, or keyword list, got: #{inspect(viewport)}"
  end

  defp viewport_dimensions!(width, height) when width > 0 and height > 0 do
    %{width: width, height: height}
  end

  defp viewport_dimensions!(width, height) do
    raise ArgumentError, ":viewport dimensions must be positive integers, got: {#{inspect(width)}, #{inspect(height)}}"
  end

  defp normalize_user_agent(nil), do: nil

  defp normalize_user_agent(user_agent) when is_binary(user_agent) do
    if String.trim(user_agent) == "" do
      raise ArgumentError, ":user_agent must be a non-empty string"
    else
      user_agent
    end
  end

  defp normalize_user_agent(user_agent) do
    raise ArgumentError, ":user_agent must be a string, got: #{inspect(user_agent)}"
  end

  defp normalize_init_scripts(scripts, script) do
    scripts_from(scripts, :init_scripts) ++ scripts_from(script, :init_script)
  end

  defp scripts_from(nil, _label), do: []

  defp scripts_from(value, _label) when is_binary(value) do
    script = String.trim(value)

    if script == "" do
      raise ArgumentError, ":init_scripts and :init_script values must be non-empty strings"
    else
      [value]
    end
  end

  defp scripts_from(values, label) when is_list(values) do
    Enum.map(values, fn
      value when is_binary(value) ->
        if String.trim(value) == "" do
          raise ArgumentError, ":#{label} entries must be non-empty strings"
        else
          value
        end

      value ->
        raise ArgumentError, ":#{label} must contain only strings, got: #{inspect(value)}"
    end)
  end

  defp scripts_from(value, label) do
    raise ArgumentError, ":#{label} must be a string or list of strings, got: #{inspect(value)}"
  end

  defp current_path_expression do
    """
    (() => JSON.stringify({ path: window.location.pathname + window.location.search }))()
    """
  end

  defp snapshot_expression(scope) do
    encoded_scope = JSON.encode!(scope)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};

      const isElementHidden = (element) => {
        let current = element;
        while (current) {
          if (current.hasAttribute("hidden")) return true;
          const style = window.getComputedStyle(current);
          if (style.display === "none" || style.visibility === "hidden") return true;
          current = current.parentElement;
        }
        return false;
      };

      const pushUnique = (list, value) => {
        if (!list.includes(value)) list.push(value);
      };

      const visible = [];
      const hiddenTexts = [];
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const elements = [];
      for (const root of roots) {
        if (!root) continue;
        elements.push(root, ...Array.from(root.querySelectorAll("*")));
      }

      for (const element of elements) {
        const tag = (element.tagName || "").toLowerCase();
        if (tag === "script" || tag === "style" || tag === "noscript") continue;

        const hidden = isElementHidden(element);
        const source = hidden ? element.textContent : (element.innerText || element.textContent);
        const value = normalize(source);
        if (!value) continue;

        if (hidden) {
          pushUnique(hiddenTexts, value);
        } else {
          pushUnique(visible, value);
        }
      }

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        visible,
        hidden: hiddenTexts
      });
    })()
    """
  end

  defp clickables_expression(scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const links = queryWithinRoots("a[href]")
        .filter(selectorMatches)
        .map((element, index) => ({
        index,
        text: normalize(element.textContent),
        href: element.getAttribute("href") || "",
        resolvedHref: element.href || ""
      }));

      const buttons = queryWithinRoots("button")
        .filter(selectorMatches)
        .map((element, index) => ({
        index,
        text: normalize(element.textContent),
        type: (element.getAttribute("type") || "submit").toLowerCase(),
        name: element.getAttribute("name") || "",
        value: element.getAttribute("value") || ""
      }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        links,
        buttons
      });
    })()
    """
  end

  defp form_fields_expression(scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const labels = new Map();

      queryWithinRoots("label[for]").forEach((label) => {
        const id = label.getAttribute("for");
        if (id) labels.set(id, normalize(label.textContent));
      });

      const labelForControl = (element) => {
        const byId = labels.get(element.id || "");
        if (byId) return byId;

        const wrappingLabel = element.closest("label");
        if (wrappingLabel) return normalize(wrappingLabel.textContent);

        return "";
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        })
        .map((element, index) => {
          const tag = (element.tagName || "").toLowerCase();
          const rawType = (element.getAttribute("type") || "").toLowerCase();
          const type = tag === "select" ? (element.multiple ? "select-multiple" : "select-one") : rawType;
          const value = tag === "select"
            ? (element.multiple
              ? Array.from(element.selectedOptions || []).map((option) => option.value || option.textContent || "")
              : (element.value || ""))
            : (element.value || "");

          return {
            index,
            id: element.id || "",
            name: element.name || "",
            label: labelForControl(element),
            type,
            value,
            checked: element.checked === true,
            tag,
            multiple: tag === "select" && element.multiple === true,
            disabled: element.disabled === true
          };
        });

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        fields
      });
    })()
    """
  end

  defp file_fields_expression(scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const labels = new Map();

      queryWithinRoots("label[for]").forEach((label) => {
        const id = label.getAttribute("for");
        if (id) labels.set(id, normalize(label.textContent));
      });

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input[type='file']")
        .filter(selectorMatches)
        .map((element, index) => ({
          index,
          id: element.id || "",
          name: element.name || "",
          label: labels.get(element.id) || ""
        }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        fields
      });
    })()
    """
  end

  defp upload_field_expression(index, file_name, mime_type, last_modified_unix_ms, content, scope, selector) do
    encoded_file_name = JSON.encode!(file_name)
    encoded_mime_type = JSON.encode!(mime_type)
    encoded_last_modified = JSON.encode!(last_modified_unix_ms)
    encoded_content = JSON.encode!(Base.encode64(content))
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const fileName = #{encoded_file_name};
      const mimeType = #{encoded_mime_type};
      const lastModified = #{encoded_last_modified};
      const contentBase64 = #{encoded_content};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input[type='file']").filter(selectorMatches);
      const field = fields[#{index}];

      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      try {
        const decoded = atob(contentBase64);
        const bytes = new Uint8Array(decoded.length);

        for (let i = 0; i < decoded.length; i += 1) {
          bytes[i] = decoded.charCodeAt(i);
        }

        const file = new File([bytes], fileName, { type: mimeType, lastModified });
        const transfer = new DataTransfer();
        transfer.items.add(file);
        field.files = transfer.files;

        field.dispatchEvent(new Event("input", { bubbles: true }));
        field.dispatchEvent(new Event("change", { bubbles: true }));

        return JSON.stringify({
          ok: true,
          path: window.location.pathname + window.location.search
        });
      } catch (error) {
        return JSON.stringify({
          ok: false,
          reason: "file_set_failed",
          message: String(error && error.message ? error.message : error)
        });
      }
    })()
    """
  end

  defp field_set_expression(index, value, scope, selector) do
    encoded_value = JSON.encode!(to_string(value))
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const value = #{encoded_value};
      field.value = value;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end

  defp select_set_expression(index, options, exact_option, preserve_existing, remembered_values, scope, selector) do
    encoded_options = JSON.encode!(options)
    encoded_exact_option = JSON.encode!(exact_option)
    encoded_preserve_existing = JSON.encode!(preserve_existing)
    encoded_remembered_values = JSON.encode!(remembered_values)
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const requestedOptions = #{encoded_options};
      const exactOption = #{encoded_exact_option};
      const preserveExisting = #{encoded_preserve_existing};
      const rememberedValues = #{encoded_remembered_values};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").replace(/\\s+/g, " ").trim();

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      if ((field.tagName || "").toLowerCase() !== "select") {
        return JSON.stringify({ ok: false, reason: "field_not_select" });
      }

      if (field.disabled) {
        return JSON.stringify({ ok: false, reason: "field_disabled" });
      }

      if (!field.multiple && requestedOptions.length > 1) {
        return JSON.stringify({ ok: false, reason: "select_not_multiple" });
      }

      const matchOption = (option, requested) => {
        const optionText = normalize(option.textContent);
        const requestedText = normalize(requested);

        if (exactOption) {
          return optionText === requestedText;
        }

        return optionText.includes(requestedText);
      };

      const matched = [];

      for (const requested of requestedOptions) {
        const enabled = Array.from(field.options || []).find((option) => matchOption(option, requested) && !option.disabled);

        if (enabled) {
          matched.push(enabled);
          continue;
        }

        const disabled = Array.from(field.options || []).find((option) => matchOption(option, requested) && option.disabled);

        if (disabled) {
          return JSON.stringify({ ok: false, reason: "option_disabled", option: requested });
        }

        return JSON.stringify({ ok: false, reason: "option_not_found", option: requested });
      }

      if (field.multiple) {
        const remembered = new Set((rememberedValues || []).map((value) => String(value)));
        const selectedValues = preserveExisting
          ? new Set(
              Array.from(field.selectedOptions || []).map((option) => option.value || normalize(option.textContent))
                .concat(Array.from(remembered))
            )
          : new Set();

        for (const option of matched) {
          selectedValues.add(option.value || normalize(option.textContent));
        }

        for (const option of Array.from(field.options || [])) {
          const value = option.value || normalize(option.textContent);
          option.selected = selectedValues.has(value);
        }
      } else {
        for (const option of Array.from(field.options || [])) {
          option.selected = false;
        }

        if (matched[0]) {
          matched[0].selected = true;
          field.value = matched[0].value || normalize(matched[0].textContent);
        }
      }

      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      const value = field.multiple
        ? Array.from(field.selectedOptions || []).map((option) => option.value || normalize(option.textContent))
        : field.value;

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search,
        value
      });
    })()
    """
  end

  defp checkbox_set_expression(index, checked, scope, selector) do
    encoded_checked = JSON.encode!(checked)
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const shouldCheck = #{encoded_checked};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const type = (field.getAttribute("type") || "").toLowerCase();
      if (type !== "checkbox") {
        return JSON.stringify({ ok: false, reason: "field_not_checkbox" });
      }

      if (field.disabled) {
        return JSON.stringify({ ok: false, reason: "field_disabled" });
      }

      field.checked = shouldCheck;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end

  defp radio_set_expression(index, scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const type = (field.getAttribute("type") || "").toLowerCase();
      if (type !== "radio") {
        return JSON.stringify({ ok: false, reason: "field_not_radio" });
      }

      if (field.disabled) {
        return JSON.stringify({ ok: false, reason: "field_disabled" });
      }

      field.checked = true;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search,
        value: field.value || "on"
      });
    })()
    """
  end

  defp button_click_expression(index, scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const buttons = queryWithinRoots("button").filter(selectorMatches);
      const button = buttons[#{index}];

      if (!button) {
        return JSON.stringify({ ok: false, reason: "button_not_found" });
      }

      button.click();

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end
end
