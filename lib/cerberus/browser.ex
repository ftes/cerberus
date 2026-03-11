defmodule Cerberus.Browser do
  @moduledoc """
  Browser-only extensions for richer real-browser workflows.

  These helpers are intentionally scoped to browser sessions.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Browser.Extensions
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Session
  alias Ecto.Adapters.SQL.Sandbox, as: EctoSandbox
  alias Phoenix.Ecto.SQL.Sandbox, as: PhoenixSandbox

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
  @type_args_error "Browser.type/4 expects locator, text as a string, and options as a keyword list"
  @press_args_error "Browser.press/4 expects locator, key as a string, and options as a keyword list"
  @drag_args_error "Browser.drag/4 expects source and target selectors as strings and options as a keyword list"
  @with_popup_args_error "Browser.with_popup/4 expects trigger callback arity 1, callback arity 2, and options as a keyword list"
  @with_evaluate_js_args_error "Browser.with_evaluate_js/3 expects an expression string and callback with arity 1"
  @with_screenshot_args_error "Browser.with_screenshot expects a path string or keyword options, optionally followed by a callback with arity 1"
  @add_cookie_args_error "Browser.add_cookie/4 expects cookie name and value strings and options as a keyword list"
  @add_cookies_args_error "Browser.add_cookies/2 expects a list of cookie keyword lists"
  @clear_cookies_args_error "Browser.clear_cookies/2 expects options as a keyword list"
  @add_session_cookie_args_error "Browser.add_session_cookie/3 expects cookie args as a keyword list and Plug.Session options as a keyword list"
  @screenshot_options_doc NimbleOptions.docs(Options.screenshot_schema())
  @type_options_doc NimbleOptions.docs(Options.browser_type_schema())
  @press_options_doc NimbleOptions.docs(Options.browser_press_schema())
  @drag_options_doc NimbleOptions.docs(Options.browser_drag_schema())
  @with_popup_options_doc NimbleOptions.docs(Options.browser_with_popup_schema())
  @add_cookie_options_doc NimbleOptions.docs(Options.browser_add_cookie_schema())
  @clear_cookies_options_doc NimbleOptions.docs(Options.browser_clear_cookies_schema())

  @doc """
  Returns encoded SQL sandbox metadata for browser `user_agent` session wiring.

  This helper is intended for browser-session sandbox wiring:

      import Cerberus
      import Cerberus.Browser

      metadata = user_agent_for_sandbox(MyApp.Repo, context)
      session(:browser, user_agent: metadata)
  """
  @spec user_agent_for_sandbox(module() | [module()], map()) :: String.t()
  def user_agent_for_sandbox(repo, context) when (is_atom(repo) or is_list(repo)) and is_map(context) do
    repo
    |> List.wrap()
    |> sandbox_metadata_for_repos(context)
    |> PhoenixSandbox.encode_metadata()
  end

  @doc """
  Returns encoded SQL sandbox metadata for the configured Cerberus Ecto repos.
  """
  @spec user_agent_for_sandbox(map()) :: String.t()
  def user_agent_for_sandbox(context) when is_map(context) do
    if repos = Application.get_env(:cerberus, :ecto_repos) do
      user_agent_for_sandbox(repos, context)
    else
      raise ArgumentError,
            "user_agent_for_sandbox/1 requires :cerberus, :ecto_repos to include at least one repo; use user_agent_for_sandbox/2 to pass an explicit repo"
    end
  end

  @doc """
  Captures a browser screenshot.

  `opts_or_path` accepts either a path string or keyword options.

  `open: true` opens the saved screenshot path in the default system image viewer.

  ## Options

  #{@screenshot_options_doc}
  """
  @spec screenshot(struct(), String.t() | Options.screenshot_opts()) :: binary()
  def screenshot(session, opts \\ [])

  def screenshot(%Browser{} = session, path) when is_binary(path) do
    screenshot(session, path: path)
  end

  def screenshot(%Browser{} = session, opts) when is_list(opts) do
    opts = Options.validate_screenshot!(opts)
    {_updated_session, png_binary, path} = capture_screenshot(session, opts)

    maybe_open_screenshot(path, opts)
    png_binary
  end

  def screenshot(_session, _opts) do
    raise ArgumentError, "Browser.screenshot/2 expects a path string or keyword options"
  end

  @doc """
  Captures a browser screenshot and returns the original session.

  Use `with_screenshot/2` when you only need the side effects (write/open), or
  `with_screenshot/3` to inspect the PNG binary while preserving piping.
  """
  @spec with_screenshot(session, String.t() | Options.screenshot_opts()) :: session when session: var
  @spec with_screenshot(session, String.t() | Options.screenshot_opts(), (binary() -> term())) :: session
        when session: var
  def with_screenshot(session, opts \\ [])

  def with_screenshot(%Browser{} = session, path) when is_binary(path) do
    with_screenshot(session, path: path)
  end

  def with_screenshot(%Browser{} = session, opts) when is_list(opts) do
    opts = Options.validate_screenshot!(opts)
    {updated_session, _png_binary, path} = capture_screenshot(session, opts)
    maybe_open_screenshot(path, opts)
    updated_session
  end

  def with_screenshot(_session, _opts_or_path) do
    raise ArgumentError, @with_screenshot_args_error
  end

  def with_screenshot(%Browser{} = session, path, callback) when is_binary(path) and is_function(callback, 1) do
    with_screenshot(session, [path: path], callback)
  end

  def with_screenshot(%Browser{} = session, opts, callback) when is_list(opts) and is_function(callback, 1) do
    opts = Options.validate_screenshot!(opts)
    {updated_session, png_binary, path} = capture_screenshot(session, opts)
    _ = callback.(png_binary)
    maybe_open_screenshot(path, opts)
    updated_session
  end

  def with_screenshot(_session, _opts_or_path, _callback) do
    raise ArgumentError, @with_screenshot_args_error
  end

  @doc """
  Types text into a matched element.

  ## Options

  #{@type_options_doc}
  """
  @spec type(session, Locator.t(), String.t(), Options.browser_type_opts()) :: session when session: var
  def type(session, locator, text, opts \\ [])

  def type(session, locator, text, opts) do
    browser_only(session, :type, opts, @type_args_error, &Options.validate_browser_type!/1, fn browser_session,
                                                                                               validated_opts ->
      if is_binary(text) do
        selector = resolve_extension_selector!(browser_session, locator, "Browser.type/4")
        extension_opts = Keyword.put(validated_opts, :selector, selector)
        {:ok, Extensions.type(browser_session, text, extension_opts)}
      else
        :invalid_args
      end
    end)
  end

  @doc """
  Presses a keyboard key on a matched element.

  ## Options

  #{@press_options_doc}
  """
  @spec press(session, Locator.t(), String.t(), Options.browser_press_opts()) :: session when session: var
  def press(session, locator, key, opts \\ [])

  def press(session, locator, key, opts) do
    browser_only(session, :press, opts, @press_args_error, &Options.validate_browser_press!/1, fn browser_session,
                                                                                                  validated_opts ->
      if is_binary(key) do
        selector = resolve_extension_selector!(browser_session, locator, "Browser.press/4")
        extension_opts = Keyword.put(validated_opts, :selector, selector)
        {:ok, Extensions.press(browser_session, key, extension_opts)}
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
  Evaluates JavaScript and returns the computed JS value.
  """
  @spec evaluate_js(struct(), String.t()) :: term()
  def evaluate_js(%Browser{} = session, expression) when is_binary(expression),
    do: Extensions.evaluate_js(session, expression)

  def evaluate_js(session, expression) when is_binary(expression), do: Assertions.unsupported(session, :evaluate_js)

  def evaluate_js(_session, _expression) do
    raise ArgumentError, "Browser.evaluate_js/2 expects an expression string"
  end

  @doc """
  Evaluates JavaScript, passes the computed value to `callback`, and returns `session`.
  """
  @spec with_evaluate_js(session, String.t(), (term() -> term())) :: session when session: var
  def with_evaluate_js(%Browser{} = session, expression, callback)
      when is_binary(expression) and is_function(callback, 1) do
    _ = callback.(Extensions.evaluate_js(session, expression))
    session
  end

  def with_evaluate_js(session, expression, callback) when is_binary(expression) and is_function(callback, 1),
    do: Assertions.unsupported(session, :with_evaluate_js)

  def with_evaluate_js(_session, _expression, _callback) do
    raise ArgumentError, @with_evaluate_js_args_error
  end

  @doc """
  Returns all browser cookies visible to the active page.
  """
  @spec cookies(struct()) :: [cookie]
  def cookies(%Browser{} = session), do: Extensions.cookies(session)
  def cookies(session), do: Assertions.unsupported(session, :cookies)

  @doc """
  Passes all browser cookies visible to the active page to `callback` and returns `session`.
  """
  @spec cookies(session, ([cookie] -> term())) :: session when session: var
  def cookies(%Browser{} = session, callback) when is_function(callback, 1) do
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
  @spec cookie(struct(), String.t()) :: cookie | nil
  def cookie(%Browser{} = session, name) when is_binary(name), do: Extensions.cookie(session, name)
  def cookie(session, _name), do: Assertions.unsupported(session, :cookie)

  @doc """
  Passes the cookie by `name` (or `nil`) to `callback` and returns `session`.
  """
  @spec cookie(session, String.t(), (cookie | nil -> term())) :: session when session: var
  def cookie(%Browser{} = session, name, callback) when is_binary(name) and is_function(callback, 1) do
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
  @spec session_cookie(struct()) :: cookie | nil
  def session_cookie(%Browser{} = session), do: Extensions.session_cookie(session)
  def session_cookie(session), do: Assertions.unsupported(session, :session_cookie)

  @doc """
  Passes the session cookie (or `nil`) to `callback` and returns `session`.
  """
  @spec session_cookie(session, (cookie | nil -> term())) :: session when session: var
  def session_cookie(%Browser{} = session, callback) when is_function(callback, 1) do
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

  @doc """
  Adds cookies to the active browser context.

  This follows Playwright's bulk cookie shape: each cookie is a keyword list with
  `:name`, `:value`, and optional `:url` or `:domain`/`:path` fields.
  When `:url`/`:domain` are omitted, Cerberus falls back to the browser session base URL.
  """
  @spec add_cookies(session, [Options.browser_cookie_arg()]) :: session when session: var
  def add_cookies(session, cookies) when is_list(cookies) do
    browser_only_list(session, :add_cookies, cookies, @add_cookies_args_error, fn browser_session ->
      validated_cookies = Enum.map(cookies, &Options.validate_browser_cookie_arg!(&1, "Browser.add_cookies/2"))
      Extensions.add_cookies(browser_session, validated_cookies)
    end)
  end

  def add_cookies(_session, _cookies) do
    raise ArgumentError, @add_cookies_args_error
  end

  @doc """
  Removes all cookies from the active browser context.

  ## Options

  #{@clear_cookies_options_doc}
  """
  @spec clear_cookies(session, Options.browser_clear_cookies_opts()) :: session when session: var
  def clear_cookies(session, opts \\ [])

  def clear_cookies(session, opts) do
    browser_only(
      session,
      :clear_cookies,
      opts,
      @clear_cookies_args_error,
      &Options.validate_browser_clear_cookies!/1,
      fn browser_session, _validated_opts ->
        {:ok, Extensions.clear_cookies(browser_session)}
      end
    )
  end

  @doc """
  Adds a Phoenix `Plug.Session` cookie to the active browser context.

  `session_options` must match the options used by `plug Plug.Session` in your endpoint
  or router. For example: `MyAppWeb.Endpoint.session_options()`.
  """
  @spec add_session_cookie(session, Options.browser_session_cookie_arg(), keyword()) :: session when session: var
  def add_session_cookie(session, cookie, session_options) when is_list(cookie) and is_list(session_options) do
    browser_only_list(session, :add_session_cookie, cookie, @add_session_cookie_args_error, fn browser_session ->
      validated_cookie = Options.validate_browser_session_cookie_arg!(cookie, "Browser.add_session_cookie/3")
      validated_session_options = Options.validate_plug_session_options!(session_options, "Browser.add_session_cookie/3")
      cookie_args = encode_session_cookie!(browser_session, validated_cookie, validated_session_options)
      Extensions.add_cookies(browser_session, [cookie_args])
    end)
  end

  def add_session_cookie(_session, _cookie, _session_options) do
    raise ArgumentError, @add_session_cookie_args_error
  end

  defp capture_screenshot(%Browser{} = session, validated_opts) when is_list(validated_opts) do
    resolved_path = Browser.screenshot_path(validated_opts)
    opts = Keyword.put(validated_opts, :path, resolved_path)
    updated_session = Browser.screenshot(session, opts)
    png_binary = File.read!(resolved_path)
    {updated_session, png_binary, resolved_path}
  end

  defp resolve_extension_selector!(%Browser{} = session, %Locator{} = locator, op_name) do
    case Browser.resolve_within_scope(session, locator, Session.scope(session)) do
      {:ok, selector} when is_binary(selector) and selector != "" ->
        selector

      {:ok, %{} = scope} ->
        raise ArgumentError,
              "#{op_name} invalid locator: resolved to iframe scope #{inspect(scope)}; Browser keyboard helpers require a document-scoped locator"

      {:ok, _other} ->
        raise ArgumentError, "#{op_name} invalid locator: did not resolve to a selector target"

      {:error, reason} ->
        raise ArgumentError, "#{op_name} invalid locator: could not be resolved: #{reason}"
    end
  end

  defp maybe_open_screenshot(path, opts) when is_binary(path) and is_list(opts) do
    if Keyword.get(opts, :open, false) do
      open_fun = Application.get_env(:cerberus, :open_with_system_cmd, &OpenBrowser.open_with_system_cmd/1)
      _ = open_fun.(path)
    end

    :ok
  end

  defp encode_session_cookie!(%Browser{} = session, cookie, session_options)
       when is_list(cookie) and is_list(session_options) do
    secret_key_base = session_secret_key_base!(session, "Browser.add_session_cookie/3")

    conn =
      "GET"
      |> Plug.Test.conn("/")
      |> then(&%{&1 | secret_key_base: secret_key_base})
      |> Plug.Session.call(Plug.Session.init(session_options))
      |> Plug.Conn.fetch_session()
      |> put_session_values!(Keyword.fetch!(cookie, :value))
      |> Plug.Conn.send_resp(200, "")

    encoded_value =
      case get_in(conn.resp_cookies, [session_options[:key], :value]) do
        value when is_binary(value) and value != "" -> value
        _other -> raise ArgumentError, "Browser.add_session_cookie/3 failed to encode session cookie"
      end

    [
      name: session_options[:key],
      value: encoded_value,
      url: Keyword.get(cookie, :url),
      domain: Keyword.get(cookie, :domain) || Keyword.get(session_options, :domain),
      path: Keyword.get(cookie, :path) || Keyword.get(session_options, :path) || "/",
      http_only: Keyword.get(cookie, :http_only, Keyword.get(session_options, :http_only, true)),
      secure: Keyword.get(cookie, :secure, Keyword.get(session_options, :secure, false)),
      same_site: Keyword.get(cookie, :same_site, Keyword.get(session_options, :same_site, :lax))
    ]
  end

  defp put_session_values!(conn, values) when is_map(values) do
    Enum.reduce(values, conn, fn {key, value}, acc -> Plug.Conn.put_session(acc, key, value) end)
  end

  defp session_secret_key_base!(%Browser{endpoint: endpoint}, op_name) when is_atom(endpoint) do
    if function_exported?(endpoint, :config, 1) do
      case endpoint.config(:secret_key_base) do
        value when is_binary(value) and value != "" ->
          value

        _other ->
          raise ArgumentError, "#{op_name} requires #{inspect(endpoint)} to configure :secret_key_base"
      end
    else
      raise ArgumentError,
            "#{op_name} requires a browser session endpoint with :secret_key_base; start session(:browser, endpoint: MyAppWeb.Endpoint) or configure :cerberus, :endpoint"
    end
  end

  defp session_secret_key_base!(_session, op_name) do
    raise ArgumentError,
          "#{op_name} requires a browser session endpoint with :secret_key_base; start session(:browser, endpoint: MyAppWeb.Endpoint) or configure :cerberus, :endpoint"
  end

  defp browser_only(session, op, opts, invalid_args_message, validator, fun)
       when is_list(opts) and is_function(validator, 1) and is_function(fun, 2) do
    case session do
      %Browser{} = browser_session ->
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

  defp browser_only_list(session, op, args, _invalid_args_message, fun) when is_list(args) and is_function(fun, 1) do
    case session do
      %Browser{} = browser_session ->
        fun.(browser_session)

      _other ->
        Assertions.unsupported(session, op)
    end
  end

  defp browser_only_list(_session, _op, _args, invalid_args_message, _fun) do
    raise ArgumentError, invalid_args_message
  end

  defp sandbox_metadata_for_repos([repo], context) do
    _ = maybe_start_sandbox_owner(repo, context)
    PhoenixSandbox.metadata_for(repo, self())
  end

  defp sandbox_metadata_for_repos(repos, context) when is_list(repos) do
    Enum.each(repos, &maybe_start_sandbox_owner(&1, context))
    PhoenixSandbox.metadata_for(repos, self())
  end

  defp maybe_start_sandbox_owner(repo, context) do
    pid = EctoSandbox.start_owner!(repo, shared: not Map.get(context, :async, false))
    ExUnit.Callbacks.on_exit(fn -> stop_sandbox_owner(pid, context) end)
    {:owner, pid}
  rescue
    e in MatchError ->
      if already_checked_out_match_error?(e),
        do: :already_checked_out,
        else: reraise(e, __STACKTRACE__)
  end

  defp stop_sandbox_owner(checkout_pid, context) when is_pid(checkout_pid) and is_map(context) do
    if Map.get(context, :async, false) do
      spawn(fn -> do_stop_sandbox_owner(checkout_pid) end)
      :ok
    else
      do_stop_sandbox_owner(checkout_pid)
    end
  end

  defp do_stop_sandbox_owner(checkout_pid) when is_pid(checkout_pid) do
    delay = Application.get_env(:cerberus, :ecto_sandbox_stop_owner_delay, 0)
    if delay > 0, do: Process.sleep(delay)
    EctoSandbox.stop_owner(checkout_pid)
  catch
    :exit, {:noproc, _} -> :ok
  end

  defp already_checked_out_match_error?(%MatchError{term: term}), do: contains_already_owner_or_allowed?(term)

  defp contains_already_owner_or_allowed?(:already_shared), do: true
  defp contains_already_owner_or_allowed?({:already, reason}) when reason in [:owner, :allowed], do: true

  defp contains_already_owner_or_allowed?(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> Enum.any?(&contains_already_owner_or_allowed?/1)
  end

  defp contains_already_owner_or_allowed?([head | tail]),
    do: contains_already_owner_or_allowed?(head) or contains_already_owner_or_allowed?(tail)

  defp contains_already_owner_or_allowed?([]), do: false
  defp contains_already_owner_or_allowed?(_term), do: false
end
