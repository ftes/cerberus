defmodule Cerberus.Browser do
  @moduledoc """
  Browser-only extensions for richer real-browser workflows.

  These helpers are intentionally scoped to browser sessions.
  Calling them with static/live sessions raises explicit unsupported errors.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.Extensions
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

  @spec type(session, String.t(), keyword()) :: session when session: var
  def type(session, text, opts \\ [])

  def type(%BrowserSession{} = session, text, opts) when is_binary(text) and is_list(opts),
    do: Extensions.type(session, text, opts)

  def type(session, _text, opts) when is_list(opts), do: Assertions.unsupported(session, :type, opts)

  def type(_session, _text, _opts) do
    raise ArgumentError, "Browser.type/3 expects text as a string and options as a keyword list"
  end

  @spec press(session, String.t(), keyword()) :: session when session: var
  def press(session, key, opts \\ [])

  def press(%BrowserSession{} = session, key, opts) when is_binary(key) and is_list(opts),
    do: Extensions.press(session, key, opts)

  def press(session, _key, opts) when is_list(opts), do: Assertions.unsupported(session, :press, opts)

  def press(_session, _key, _opts) do
    raise ArgumentError, "Browser.press/3 expects key as a string and options as a keyword list"
  end

  @spec drag(session, String.t(), String.t()) :: session when session: var
  def drag(%BrowserSession{} = session, source_selector, target_selector)
      when is_binary(source_selector) and is_binary(target_selector) do
    Extensions.drag(session, source_selector, target_selector)
  end

  def drag(session, _source_selector, _target_selector), do: Assertions.unsupported(session, :drag)

  @spec with_dialog(session, (session -> term()), keyword()) :: session when session: var
  def with_dialog(session, action, opts \\ [])

  def with_dialog(%BrowserSession{} = session, action, opts) when is_function(action, 1) and is_list(opts) do
    Extensions.with_dialog(session, action, opts)
  end

  def with_dialog(%BrowserSession{}, _action, opts) when is_list(opts) do
    raise ArgumentError, "Browser.with_dialog/3 expects a callback with arity 1 and options as a keyword list"
  end

  def with_dialog(session, _action, opts) when is_list(opts), do: Assertions.unsupported(session, :with_dialog, opts)

  def with_dialog(_session, _action, _opts) do
    raise ArgumentError, "Browser.with_dialog/3 expects a callback with arity 1 and options as a keyword list"
  end

  @spec with_popup(session, (session -> term()), (session, session -> term()), keyword()) :: session when session: var
  def with_popup(session, trigger_fun, callback_fun, opts \\ [])

  def with_popup(%BrowserSession{} = session, trigger_fun, callback_fun, opts)
      when is_function(trigger_fun, 1) and is_function(callback_fun, 2) and is_list(opts) do
    Extensions.with_popup(session, trigger_fun, callback_fun, opts)
  end

  def with_popup(%BrowserSession{}, _trigger_fun, _callback_fun, opts) when is_list(opts) do
    raise ArgumentError,
          "Browser.with_popup/4 expects trigger callback arity 1, callback arity 2, and options as a keyword list"
  end

  def with_popup(session, _trigger_fun, _callback_fun, opts) when is_list(opts),
    do: Assertions.unsupported(session, :with_popup, opts)

  def with_popup(_session, _trigger_fun, _callback_fun, _opts) do
    raise ArgumentError,
          "Browser.with_popup/4 expects trigger callback arity 1, callback arity 2, and options as a keyword list"
  end

  @spec evaluate_js(Session.t(), String.t()) :: term()
  def evaluate_js(%BrowserSession{} = session, expression) when is_binary(expression) do
    Extensions.evaluate_js(session, expression)
  end

  def evaluate_js(session, _expression), do: Assertions.unsupported(session, :evaluate_js)

  @spec evaluate_js(Session.t(), String.t(), (term() -> term())) :: Session.t()
  def evaluate_js(%BrowserSession{} = session, expression, callback)
      when is_binary(expression) and is_function(callback, 1) do
    session
    |> Extensions.evaluate_js(expression)
    |> callback.()

    session
  end

  def evaluate_js(session, _expression, callback) when is_function(callback, 1) do
    Assertions.unsupported(session, :evaluate_js)
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

  @spec add_cookie(session, String.t(), String.t(), keyword()) :: session when session: var
  def add_cookie(session, name, value, opts \\ [])

  def add_cookie(%BrowserSession{} = session, name, value, opts)
      when is_binary(name) and is_binary(value) and is_list(opts) do
    Extensions.add_cookie(session, name, value, opts)
  end

  def add_cookie(session, _name, _value, _opts), do: Assertions.unsupported(session, :add_cookie)
end
