defmodule Cerberus.Browser do
  @moduledoc """
  Browser-only extensions for richer real-browser workflows.

  Most helpers are intentionally scoped to browser sessions.
  `assert_download/3` also works for static/live sessions by inspecting
  response download headers.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.Extensions
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Session
  alias ExUnit.AssertionError

  @type cookie :: %{
          name: String.t() | nil,
          value: term(),
          domain: String.t() | nil,
          path: String.t() | nil,
          http_only: boolean(),
          secure: boolean(),
          same_site: String.t() | nil,
          session: boolean()
        }
  @type_args_error "Browser.type/3 expects text as a string and options as a keyword list"
  @press_args_error "Browser.press/3 expects key as a string and options as a keyword list"
  @drag_args_error "Browser.drag/4 expects source and target selectors as strings and options as a keyword list"
  @assert_dialog_args_error "Browser.assert_dialog/3 expects a text locator and options as a keyword list"
  @with_popup_args_error "Browser.with_popup/4 expects trigger callback arity 1, callback arity 2, and options as a keyword list"
  @assert_download_args_error "Browser.assert_download/3 expects a filename string and options as a keyword list"
  @add_cookie_args_error "Browser.add_cookie/4 expects cookie name and value strings and options as a keyword list"

  @spec screenshot(session, String.t() | keyword()) :: session when session: var
  def screenshot(session, opts \\ [])

  @spec screenshot(arg, String.t() | Options.screenshot_opts()) :: arg when arg: var
  def screenshot(%BrowserSession{} = session, path) when is_binary(path) do
    opts = Options.validate_screenshot!(path: path)
    BrowserSession.screenshot(session, opts)
  end

  def screenshot(%BrowserSession{} = session, opts) when is_list(opts) do
    opts = Options.validate_screenshot!(opts)
    BrowserSession.screenshot(session, opts)
  end

  def screenshot(_session, _opts) do
    raise ArgumentError, "Browser.screenshot/2 expects a path string or keyword options"
  end

  @spec type(session, String.t(), Options.browser_type_opts()) :: session when session: var
  def type(session, text, opts \\ [])

  def type(session, text, opts) do
    browser_only(session, :type, opts, @type_args_error, &Options.validate_browser_type!/1, fn browser_session,
                                                                                               validated_opts ->
      if is_binary(text) do
        {:ok, Extensions.type(browser_session, text, validated_opts)}
      else
        :invalid_args
      end
    end)
  end

  @spec press(session, String.t(), Options.browser_press_opts()) :: session when session: var
  def press(session, key, opts \\ [])

  def press(session, key, opts) do
    browser_only(session, :press, opts, @press_args_error, &Options.validate_browser_press!/1, fn browser_session,
                                                                                                  validated_opts ->
      if is_binary(key) do
        {:ok, Extensions.press(browser_session, key, validated_opts)}
      else
        :invalid_args
      end
    end)
  end

  @spec drag(session, String.t(), String.t(), Options.browser_drag_opts()) :: session when session: var
  def drag(session, source_selector, target_selector, opts \\ [])

  def drag(session, source_selector, target_selector, opts) do
    browser_only(session, :drag, opts, @drag_args_error, &Options.validate_browser_drag!/1, fn browser_session,
                                                                                               validated_opts ->
      if is_binary(source_selector) and is_binary(target_selector) do
        {:ok, Extensions.drag(browser_session, source_selector, target_selector, validated_opts)}
      else
        :invalid_args
      end
    end)
  end

  @spec assert_dialog(session, Locator.input(), Options.browser_assert_dialog_opts()) :: session when session: var
  def assert_dialog(session, locator, opts \\ [])

  def assert_dialog(session, locator, opts) do
    browser_only(
      session,
      :assert_dialog,
      opts,
      @assert_dialog_args_error,
      &Options.validate_browser_assert_dialog!/1,
      fn browser_session, validated_opts ->
        normalized_locator = Locator.normalize(locator)

        if normalized_locator.kind == :text do
          {:ok, Extensions.assert_dialog(browser_session, normalized_locator, validated_opts)}
        else
          :invalid_args
        end
      end
    )
  end

  @spec with_popup(
          session,
          (session -> term()),
          (session, session -> term()),
          Options.browser_with_popup_opts()
        ) :: session
        when session: var
  def with_popup(session, trigger_fun, callback_fun, opts \\ [])

  def with_popup(session, trigger_fun, callback_fun, opts) do
    browser_only(
      session,
      :with_popup,
      opts,
      @with_popup_args_error,
      &Options.validate_browser_with_popup!/1,
      fn browser_session, validated_opts ->
        if is_function(trigger_fun, 1) and is_function(callback_fun, 2) do
          {:ok, Extensions.with_popup(browser_session, trigger_fun, callback_fun, validated_opts)}
        else
          :invalid_args
        end
      end
    )
  end

  @spec assert_download(session, String.t(), Options.browser_assert_download_opts()) :: session when session: var
  def assert_download(session, filename, opts \\ [])

  def assert_download(session, filename, opts) when is_list(opts) do
    validated_opts = Options.validate_browser_assert_download!(opts)

    if is_binary(filename) do
      assert_download_for_session(session, filename, validated_opts)
    else
      raise ArgumentError, @assert_download_args_error
    end
  end

  def assert_download(_session, _filename, _opts) do
    raise ArgumentError, @assert_download_args_error
  end

  @spec evaluate_js(Session.t(), String.t()) :: term()
  def evaluate_js(session, expression) do
    case evaluate_js_value(session, expression) do
      {:ok, value} -> value
      {:unsupported, unsupported_session} -> Assertions.unsupported(unsupported_session, :evaluate_js)
    end
  end

  @spec evaluate_js(Session.t(), String.t(), (term() -> term())) :: Session.t()
  def evaluate_js(session, expression, callback) when is_function(callback, 1) do
    case evaluate_js_value(session, expression) do
      {:ok, value} ->
        callback.(value)
        session

      {:unsupported, unsupported_session} ->
        Assertions.unsupported(unsupported_session, :evaluate_js)
    end
  end

  def evaluate_js(_session, _expression, _callback) do
    raise ArgumentError, "Browser.evaluate_js/3 expects an expression string and callback with arity 1"
  end

  @spec cookies(Session.t()) :: [cookie]
  def cookies(%BrowserSession{} = session), do: Extensions.cookies(session)
  def cookies(session), do: Assertions.unsupported(session, :cookies)

  @spec cookie(Session.t(), String.t()) :: cookie | nil
  def cookie(%BrowserSession{} = session, name) when is_binary(name), do: Extensions.cookie(session, name)
  def cookie(session, _name), do: Assertions.unsupported(session, :cookie)

  @spec session_cookie(Session.t()) :: cookie | nil
  def session_cookie(%BrowserSession{} = session), do: Extensions.session_cookie(session)
  def session_cookie(session), do: Assertions.unsupported(session, :session_cookie)

  @spec add_cookie(session, String.t(), String.t(), Options.browser_add_cookie_opts()) :: session when session: var
  def add_cookie(session, name, value, opts \\ [])

  def add_cookie(session, name, value, opts) do
    browser_only(
      session,
      :add_cookie,
      opts,
      @add_cookie_args_error,
      &Options.validate_browser_add_cookie!/1,
      fn browser_session, validated_opts ->
        if is_binary(name) and is_binary(value) do
          {:ok, Extensions.add_cookie(browser_session, name, value, validated_opts)}
        else
          :invalid_args
        end
      end
    )
  end

  defp evaluate_js_value(%BrowserSession{} = session, expression) when is_binary(expression) do
    {:ok, Extensions.evaluate_js(session, expression)}
  end

  defp evaluate_js_value(session, _expression), do: {:unsupported, session}

  defp assert_download_for_session(%BrowserSession{} = session, filename, validated_opts) do
    Extensions.assert_download(session, filename, validated_opts)
  end

  defp assert_download_for_session(%StaticSession{} = session, filename, _validated_opts) do
    assert_download_from_conn!(session, filename)
  end

  defp assert_download_for_session(%LiveSession{} = session, filename, _validated_opts) do
    assert_download_from_conn!(session, filename)
  end

  defp assert_download_for_session(session, _filename, opts) do
    Assertions.unsupported(session, :assert_download, opts)
  end

  defp assert_download_from_conn!(%{conn: %Plug.Conn{} = conn} = session, expected_filename)
       when is_binary(expected_filename) do
    filename = non_empty_text!(expected_filename, "assert_download/3 filename")
    observed_filenames = response_download_filenames(conn)

    if filename in observed_filenames do
      session
    else
      raise AssertionError,
        message:
          "assert_download/3 expected #{inspect(filename)} from response content-disposition; observed downloads: #{inspect(observed_filenames)}"
    end
  end

  defp assert_download_from_conn!(_session, _expected_filename) do
    raise AssertionError,
      message: "assert_download/3 requires a response-backed static/live session with an available conn"
  end

  defp response_download_filenames(conn) do
    conn
    |> Plug.Conn.get_resp_header("content-disposition")
    |> Enum.flat_map(&extract_content_disposition_filenames/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_content_disposition_filenames(header) when is_binary(header) do
    segments =
      header
      |> String.split(";")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    filename_star =
      Enum.find_value(segments, &disposition_segment_value(&1, "filename*", :extended))

    filename =
      Enum.find_value(segments, &disposition_segment_value(&1, "filename", :basic))

    Enum.filter([filename_star, filename], &(is_binary(&1) and &1 != ""))
  end

  defp extract_content_disposition_filenames(_header), do: []

  defp disposition_segment_value(segment, expected_key, mode) when is_binary(segment) and is_binary(expected_key) do
    case String.split(segment, "=", parts: 2) do
      [key, value] ->
        if String.downcase(String.trim(key)) == expected_key do
          decode_disposition_param_value(value, mode)
        end

      _ ->
        nil
    end
  end

  defp decode_disposition_param_value(value, mode) when is_binary(value) do
    value
    |> String.trim()
    |> trim_wrapping_quotes()
    |> decode_disposition_value(mode)
    |> String.trim()
  end

  defp decode_disposition_value(value, :extended) when is_binary(value) do
    case String.split(value, "''", parts: 2) do
      [_charset, encoded] -> URI.decode(encoded)
      _ -> URI.decode(value)
    end
  rescue
    _ -> value
  end

  defp decode_disposition_value(value, :basic), do: value

  defp trim_wrapping_quotes(value) when is_binary(value) do
    if String.starts_with?(value, "\"") and String.ends_with?(value, "\"") and byte_size(value) >= 2 do
      value
      |> String.trim_leading("\"")
      |> String.trim_trailing("\"")
    else
      value
    end
  end

  defp non_empty_text!(value, label) when is_binary(value) do
    if String.trim(value) == "" do
      raise ArgumentError, "#{label} must be a non-empty string"
    else
      value
    end
  end

  defp browser_only(session, op, opts, invalid_args_message, validator, fun)
       when is_list(opts) and is_function(validator, 1) and is_function(fun, 2) do
    case session do
      %BrowserSession{} = browser_session ->
        validated_opts = validator.(opts)

        case fun.(browser_session, validated_opts) do
          {:ok, result} -> result
          :invalid_args -> raise ArgumentError, invalid_args_message
        end

      _other ->
        Assertions.unsupported(session, op, opts)
    end
  end

  defp browser_only(_session, _op, _opts, invalid_args_message, _validator, _fun) do
    raise ArgumentError, invalid_args_message
  end
end
