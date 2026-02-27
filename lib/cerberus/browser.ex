defmodule Cerberus.Browser do
  @moduledoc """
  Browser-only extensions for richer real-browser workflows.

  These helpers are intentionally scoped to browser sessions.
  Calling them with static/live sessions raises explicit unsupported errors.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Browser.Extensions
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
  def screenshot(%BrowserSession{} = session, path) when is_binary(path), do: Cerberus.screenshot(session, path)
  def screenshot(%BrowserSession{} = session, opts) when is_list(opts), do: Cerberus.screenshot(session, opts)
  def screenshot(session, path) when is_binary(path), do: Assertions.unsupported(session, :screenshot, path: path)
  def screenshot(session, opts) when is_list(opts), do: Assertions.unsupported(session, :screenshot, opts)

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

  @spec with_dialog(session, (session -> session), keyword()) :: session when session: var
  def with_dialog(session, action, opts \\ [])

  def with_dialog(%BrowserSession{} = session, action, opts) when is_function(action, 1) and is_list(opts) do
    Extensions.with_dialog(session, action, opts)
  end

  def with_dialog(session, _action, opts) when is_list(opts), do: Assertions.unsupported(session, :with_dialog, opts)

  def with_dialog(_session, _action, _opts) do
    raise ArgumentError, "Browser.with_dialog/3 expects a callback with arity 1 and options as a keyword list"
  end

  @spec evaluate_js(Session.t(), String.t()) :: term()
  def evaluate_js(%BrowserSession{} = session, expression) when is_binary(expression) do
    Extensions.evaluate_js(session, expression)
  end

  def evaluate_js(session, _expression), do: Assertions.unsupported(session, :evaluate_js)

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
