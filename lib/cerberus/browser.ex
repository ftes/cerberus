defmodule Cerberus.Browser do
  @moduledoc """
  Browser-only extensions for richer real-browser workflows.

  These helpers are intentionally scoped to browser sessions.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.Extensions
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Session

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
  @add_cookie_args_error "Browser.add_cookie/4 expects cookie name and value strings and options as a keyword list"
  @screenshot_options_doc NimbleOptions.docs(Options.screenshot_schema())
  @type_options_doc NimbleOptions.docs(Options.browser_type_schema())
  @press_options_doc NimbleOptions.docs(Options.browser_press_schema())
  @drag_options_doc NimbleOptions.docs(Options.browser_drag_schema())
  @assert_dialog_options_doc NimbleOptions.docs(Options.browser_assert_dialog_schema())
  @with_popup_options_doc NimbleOptions.docs(Options.browser_with_popup_schema())
  @add_cookie_options_doc NimbleOptions.docs(Options.browser_add_cookie_schema())
  @return_result_options_doc NimbleOptions.docs(Options.return_result_schema())

  @doc """
  Captures a browser screenshot.

  `opts_or_path` accepts either a path string or keyword options.

  Use either:
  - callback form (`screenshot(session, opts, fn png_binary -> ... end)`) to keep piping
  - `return_result: true` to return the PNG binary

  `open: true` opens the saved screenshot path in the default system image viewer.

  ## Options

  #{@screenshot_options_doc}
  """
  @spec screenshot(session, String.t() | Options.screenshot_opts()) :: session | binary() when session: var
  @spec screenshot(session, String.t() | Options.screenshot_opts(), (binary() -> term())) :: session when session: var
  def screenshot(session, opts \\ [])

  def screenshot(%BrowserSession{} = session, path) when is_binary(path) do
    screenshot(session, path: path)
  end

  def screenshot(%BrowserSession{} = session, opts) when is_list(opts) do
    opts = Options.validate_screenshot!(opts)
    {updated_session, png_binary, path} = capture_screenshot(session, opts)

    maybe_open_screenshot(path, opts)

    if Keyword.get(opts, :return_result, false) do
      png_binary
    else
      updated_session
    end
  end

  def screenshot(_session, _opts) do
    raise ArgumentError, "Browser.screenshot/2 expects a path string or keyword options"
  end

  def screenshot(%BrowserSession{} = session, path, callback) when is_binary(path) and is_function(callback, 1) do
    screenshot(session, [path: path], callback)
  end

  def screenshot(%BrowserSession{} = session, opts, callback) when is_list(opts) and is_function(callback, 1) do
    opts = Options.validate_screenshot!(opts)
    {updated_session, png_binary, path} = capture_screenshot(session, opts)
    _ = callback.(png_binary)
    maybe_open_screenshot(path, opts)
    updated_session
  end

  def screenshot(_session, _opts_or_path, _callback) do
    raise ArgumentError, "Browser.screenshot/3 expects a path string or keyword options and callback with arity 1"
  end

  @doc """
  Types text into the currently focused element or a matched element.

  ## Options

  #{@type_options_doc}
  """
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

  @doc """
  Presses a keyboard key.

  ## Options

  #{@press_options_doc}
  """
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

  @doc """
  Drags from `source_selector` to `target_selector`.

  ## Options

  #{@drag_options_doc}
  """
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

  @doc """
  Asserts that a dialog matching the text locator was observed.

  Browser operations auto-accept dialogs. `assert_dialog/3` only matches dialog text
  from the active dialog or recently observed dialog events.
  Prompt dialogs are auto-accepted with an empty string input.

  ## Options

  #{@assert_dialog_options_doc}
  """
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
        normalized_locator = Locator.normalize!(locator)

        if normalized_locator.kind == :text do
          {:ok, Extensions.assert_dialog(browser_session, normalized_locator, validated_opts)}
        else
          :invalid_args
        end
      end
    )
  end

  @doc """
  Runs a popup flow, yielding both main and popup sessions to `callback_fun`.

  ## Options

  #{@with_popup_options_doc}
  """
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

  @doc """
  Evaluates JavaScript and ignores the result, returning the original session.
  """
  @spec evaluate_js(Session.t(), String.t()) :: Session.t()
  def evaluate_js(session, expression) when is_binary(expression) do
    evaluate_js(session, expression, [])
  end

  def evaluate_js(_session, _expression) do
    raise ArgumentError, "Browser.evaluate_js/2 expects an expression string"
  end

  @doc """
  Evaluates JavaScript and controls result handling.

  Use either:
  - callback form (`evaluate_js(session, expression, fn value -> ... end)`) to keep piping
  - `return_result: true` (`evaluate_js(session, expression, return_result: true)`) to return the JS value

  ## Options

  #{@return_result_options_doc}
  """
  @spec evaluate_js(Session.t(), String.t(), Options.return_result_opts()) :: Session.t() | term()
  @spec evaluate_js(Session.t(), String.t(), (term() -> term())) :: Session.t()
  def evaluate_js(session, expression, callback_or_opts)
      when is_binary(expression) and (is_function(callback_or_opts, 1) or is_list(callback_or_opts)) do
    case evaluate_js_value(session, expression) do
      {:ok, value} ->
        case callback_or_opts do
          callback when is_function(callback, 1) ->
            callback.(value)
            session

          opts ->
            opts = Options.validate_return_result!(opts, "Browser.evaluate_js/3")

            if Keyword.get(opts, :return_result, false) do
              value
            else
              session
            end
        end

      {:unsupported, unsupported_session} ->
        Assertions.unsupported(unsupported_session, :evaluate_js)
    end
  end

  def evaluate_js(_session, _expression, _callback_or_opts) do
    raise ArgumentError, "Browser.evaluate_js/3 expects an expression string and callback with arity 1 or keyword options"
  end

  @doc """
  Returns all browser cookies visible to the active page.
  """
  @spec cookies(Session.t()) :: [cookie]
  def cookies(%BrowserSession{} = session), do: Extensions.cookies(session)
  def cookies(session), do: Assertions.unsupported(session, :cookies)

  @doc """
  Passes all browser cookies visible to the active page to `callback` and returns `session`.
  """
  @spec cookies(session, ([cookie] -> term())) :: session when session: var
  def cookies(%BrowserSession{} = session, callback) when is_function(callback, 1) do
    _ = callback.(Extensions.cookies(session))
    session
  end

  def cookies(session, callback) when is_function(callback, 1), do: Assertions.unsupported(session, :cookies)

  def cookies(_session, _callback) do
    raise ArgumentError, "Browser.cookies/2 expects a callback with arity 1"
  end

  @doc """
  Returns the cookie by `name` or `nil` when not present.
  """
  @spec cookie(Session.t(), String.t()) :: cookie | nil
  def cookie(%BrowserSession{} = session, name) when is_binary(name), do: Extensions.cookie(session, name)
  def cookie(session, _name), do: Assertions.unsupported(session, :cookie)

  @doc """
  Passes the cookie by `name` (or `nil`) to `callback` and returns `session`.
  """
  @spec cookie(session, String.t(), (cookie | nil -> term())) :: session when session: var
  def cookie(%BrowserSession{} = session, name, callback) when is_binary(name) and is_function(callback, 1) do
    _ = callback.(Extensions.cookie(session, name))
    session
  end

  def cookie(session, _name, callback) when is_function(callback, 1), do: Assertions.unsupported(session, :cookie)

  def cookie(_session, _name, _callback) do
    raise ArgumentError, "Browser.cookie/3 expects a cookie name string and callback with arity 1"
  end

  @doc """
  Returns the session cookie (commonly `_app_key`) when present.
  """
  @spec session_cookie(Session.t()) :: cookie | nil
  def session_cookie(%BrowserSession{} = session), do: Extensions.session_cookie(session)
  def session_cookie(session), do: Assertions.unsupported(session, :session_cookie)

  @doc """
  Passes the session cookie (or `nil`) to `callback` and returns `session`.
  """
  @spec session_cookie(session, (cookie | nil -> term())) :: session when session: var
  def session_cookie(%BrowserSession{} = session, callback) when is_function(callback, 1) do
    _ = callback.(Extensions.session_cookie(session))
    session
  end

  def session_cookie(session, callback) when is_function(callback, 1),
    do: Assertions.unsupported(session, :session_cookie)

  def session_cookie(_session, _callback) do
    raise ArgumentError, "Browser.session_cookie/2 expects a callback with arity 1"
  end

  @doc """
  Adds a cookie to the active browser context.

  ## Options

  #{@add_cookie_options_doc}
  """
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

  defp capture_screenshot(%BrowserSession{} = session, validated_opts) when is_list(validated_opts) do
    resolved_path = BrowserSession.screenshot_path(validated_opts)
    opts = Keyword.put(validated_opts, :path, resolved_path)
    updated_session = BrowserSession.screenshot(session, opts)
    png_binary = File.read!(resolved_path)
    {updated_session, png_binary, resolved_path}
  end

  defp maybe_open_screenshot(path, opts) when is_binary(path) and is_list(opts) do
    if Keyword.get(opts, :open, false) do
      open_fun = Application.get_env(:cerberus, :open_with_system_cmd, &OpenBrowser.open_with_system_cmd/1)
      _ = open_fun.(path)
    end

    :ok
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
