defmodule Cerberus.Browser do
  @moduledoc """
  Browser-only extensions for richer real-browser workflows.

  These helpers are intentionally scoped to browser sessions.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.Extensions
  alias Cerberus.Locator
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

  @doc """
  Captures a browser screenshot.

  `opts_or_path` accepts either a path string or keyword options.

  ## Options

  #{@screenshot_options_doc}
  """
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
  Asserts the next dialog text matches a text locator and accepts or dismisses it.

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
        normalized_locator = Locator.normalize(locator)

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
  Evaluates JavaScript in the active page and returns the decoded result value.
  """
  @spec evaluate_js(Session.t(), String.t()) :: term()
  def evaluate_js(session, expression) do
    case evaluate_js_value(session, expression) do
      {:ok, value} -> value
      {:unsupported, unsupported_session} -> Assertions.unsupported(unsupported_session, :evaluate_js)
    end
  end

  @doc """
  Evaluates JavaScript and passes the result to `callback`, returning the original session.
  """
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

  @doc """
  Returns all browser cookies visible to the active page.
  """
  @spec cookies(Session.t()) :: [cookie]
  def cookies(%BrowserSession{} = session), do: Extensions.cookies(session)
  def cookies(session), do: Assertions.unsupported(session, :cookies)

  @doc """
  Returns the cookie by `name` or `nil` when not present.
  """
  @spec cookie(Session.t(), String.t()) :: cookie | nil
  def cookie(%BrowserSession{} = session, name) when is_binary(name), do: Extensions.cookie(session, name)
  def cookie(session, _name), do: Assertions.unsupported(session, :cookie)

  @doc """
  Returns the session cookie (commonly `_app_key`) when present.
  """
  @spec session_cookie(Session.t()) :: cookie | nil
  def session_cookie(%BrowserSession{} = session), do: Extensions.session_cookie(session)
  def session_cookie(session), do: Assertions.unsupported(session, :session_cookie)

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
