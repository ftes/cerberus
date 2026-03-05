defmodule Cerberus.PhoenixTestShim do
  @moduledoc """
  PhoenixTest-style compatibility facade for Cerberus.

  This shim is intended as a migration bridge. It keeps familiar PhoenixTest call
  shapes while delegating into explicit Cerberus APIs.

  Scope is intentionally pragmatic: common assertions, form actions, navigation,
  and selected browser helpers are covered. For advanced/edge PhoenixTest patterns,
  migrate directly to native Cerberus calls.
  """

  alias Cerberus.Browser
  alias Cerberus.Locator
  alias Phoenix.HTML.Safe

  @doc """
  Imports shim helpers and aliases nested compatibility modules.
  """
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      alias unquote(__MODULE__).Assertions
      alias unquote(__MODULE__).TestHelpers
    end
  end

  @doc """
  Visits `path` from a Cerberus session or `Plug.Conn`.
  """
  def visit(session_or_conn, path), do: Cerberus.visit(ensure_session(session_or_conn), path)

  @doc """
  Reloads the current page.
  """
  def reload_page(session), do: Cerberus.reload_page(ensure_session(session))

  @doc """
  Returns the current path.
  """
  def current_path(session), do: Cerberus.current_path(ensure_session(session))

  def assert_has(session, selector) do
    {locator, opts} = normalize_assert_request(selector, [])
    Cerberus.assert_has(ensure_session(session), locator, opts)
  end

  def assert_has(session, selector, opts) when is_list(opts) do
    {locator, normalized_opts} = normalize_assert_request(selector, opts)
    Cerberus.assert_has(ensure_session(session), locator, normalized_opts)
  end

  def assert_has(session, selector, text), do: assert_has(session, selector, text: normalize_scalar(text))

  def assert_has(session, selector, text, opts) when is_list(opts),
    do: assert_has(session, selector, Keyword.put(opts, :text, normalize_scalar(text)))

  def refute_has(session, selector) do
    {locator, opts} = normalize_assert_request(selector, [])
    Cerberus.refute_has(ensure_session(session), locator, opts)
  end

  def refute_has(session, selector, opts) when is_list(opts) do
    {locator, normalized_opts} = normalize_assert_request(selector, opts)
    Cerberus.refute_has(ensure_session(session), locator, normalized_opts)
  end

  def refute_has(session, selector, text), do: refute_has(session, selector, text: normalize_scalar(text))

  def refute_has(session, selector, text, opts) when is_list(opts),
    do: refute_has(session, selector, Keyword.put(opts, :text, normalize_scalar(text)))

  def assert_path(session, expected, opts \\ []) do
    Cerberus.assert_path(ensure_session(session), expected, normalize_path_opts(opts))
  end

  def refute_path(session, expected, opts \\ []) do
    Cerberus.refute_path(ensure_session(session), expected, normalize_path_opts(opts))
  end

  @doc """
  Clicks a target by CSS-like selector or text-like value.
  """
  def click(session, target, opts \\ []) when is_list(opts) do
    locator = click_locator(target, opts)
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.click(ensure_session(session), locator, action_opts)
  end

  def click_link(session, text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.link(normalize_scalar(text), exact: false))
  end

  def click_link(session, selector, text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.link(Cerberus.css(selector), normalize_scalar(text), exact: false))
  end

  def click_button(session, text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.button(normalize_scalar(text), exact: false))
  end

  def click_button(session, selector, text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.button(Cerberus.css(selector), normalize_scalar(text), exact: false))
  end

  def fill_in(session, field_or_selector, opts) when is_list(opts) do
    value = Keyword.fetch!(opts, :with)
    locator = field_locator(field_or_selector, opts)
    action_opts = Keyword.drop(opts, [:with, :exact])

    Cerberus.fill_in(ensure_session(session), locator, value, action_opts)
  end

  def fill_in(session, selector, field, opts) when is_list(opts) do
    value = Keyword.fetch!(opts, :with)
    locator = Cerberus.label(Cerberus.css(selector), normalize_scalar(field), exact: Keyword.get(opts, :exact, false))
    action_opts = Keyword.drop(opts, [:with, :exact])

    Cerberus.fill_in(ensure_session(session), locator, value, action_opts)
  end

  def select(session, field_or_selector, opts) when is_list(opts) do
    normalized_opts = normalize_select_opts(opts)
    locator = field_locator(field_or_selector, opts)
    Cerberus.select(ensure_session(session), locator, normalized_opts)
  end

  def select(session, selector, field, opts) when is_list(opts) do
    normalized_opts = normalize_select_opts(opts)

    locator =
      Cerberus.label(Cerberus.css(selector), normalize_scalar(field), exact: Keyword.get(opts, :exact, false))

    Cerberus.select(ensure_session(session), locator, normalized_opts)
  end

  def choose(session, field_or_selector, opts \\ [])

  def choose(session, selector, field) when is_binary(selector) and not is_list(field) do
    Cerberus.choose(ensure_session(session), Cerberus.css(selector))
  end

  def choose(session, field_or_selector, opts) when is_list(opts) do
    locator = field_locator(field_or_selector, opts)
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.choose(ensure_session(session), locator, action_opts)
  end

  def choose(session, selector, field, opts) when is_list(opts) do
    locator = Cerberus.label(Cerberus.css(selector), normalize_scalar(field), exact: Keyword.get(opts, :exact, false))
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.choose(ensure_session(session), locator, action_opts)
  end

  def check(session, field_or_selector, opts \\ [])

  def check(session, selector, field) when is_binary(selector) and not is_list(field) do
    Cerberus.check(ensure_session(session), Cerberus.css(selector))
  end

  def check(session, field_or_selector, opts) when is_list(opts) do
    locator = field_locator(field_or_selector, opts)
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.check(ensure_session(session), locator, action_opts)
  end

  def check(session, selector, field, opts) when is_list(opts) do
    locator = Cerberus.label(Cerberus.css(selector), normalize_scalar(field), exact: Keyword.get(opts, :exact, false))
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.check(ensure_session(session), locator, action_opts)
  end

  def uncheck(session, field_or_selector, opts \\ [])

  def uncheck(session, selector, field) when is_binary(selector) and not is_list(field) do
    Cerberus.uncheck(ensure_session(session), Cerberus.css(selector))
  end

  def uncheck(session, field_or_selector, opts) when is_list(opts) do
    locator = field_locator(field_or_selector, opts)
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.uncheck(ensure_session(session), locator, action_opts)
  end

  def uncheck(session, selector, field, opts) when is_list(opts) do
    locator = Cerberus.label(Cerberus.css(selector), normalize_scalar(field), exact: Keyword.get(opts, :exact, false))
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.uncheck(ensure_session(session), locator, action_opts)
  end

  def upload(session, field_or_selector, path), do: upload(session, field_or_selector, path, [])

  def upload(session, field_or_selector, path, opts) when is_list(opts) do
    locator = field_locator(field_or_selector, opts)
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.upload(ensure_session(session), locator, resolve_upload_path(path), action_opts)
  end

  def upload(session, selector, field, path), do: upload(session, selector, field, path, [])

  def upload(session, selector, field, path, opts) when is_list(opts) do
    locator = Cerberus.label(Cerberus.css(selector), normalize_scalar(field), exact: Keyword.get(opts, :exact, false))
    action_opts = Keyword.delete(opts, :exact)
    Cerberus.upload(ensure_session(session), locator, resolve_upload_path(path), action_opts)
  end

  def submit(session), do: Cerberus.submit(ensure_session(session))

  def submit(session, text) do
    session
    |> ensure_session()
    |> Cerberus.submit(Cerberus.button(normalize_scalar(text), exact: false))
  end

  def within(session, selector, callback) when is_function(callback, 1) do
    scoped_locator = if is_binary(selector), do: Cerberus.css(selector), else: selector
    Cerberus.within(ensure_session(session), scoped_locator, callback)
  end

  def open_browser(session), do: Cerberus.open_browser(ensure_session(session))
  def open_browser(session, open_fun), do: Cerberus.open_browser(ensure_session(session), open_fun)

  def unwrap(session, callback) when is_function(callback, 1), do: Cerberus.unwrap(ensure_session(session), callback)

  @doc """
  Runs a dialog-producing trigger and asserts dialog text.

  Supports both argument orders used in PhoenixTest codebases:
  `with_dialog(session, expected, trigger_fun, opts)` and
  `with_dialog(session, trigger_fun, expected, opts)`.
  """
  def with_dialog(session, expected, trigger_fun, opts \\ [])

  def with_dialog(session, expected, trigger_fun, opts) when is_function(trigger_fun, 1) and is_list(opts) do
    session
    |> ensure_session()
    |> trigger_fun.()
    |> ensure_session()
    |> Browser.assert_dialog(dialog_text_locator(expected), opts)
  end

  def with_dialog(session, trigger_fun, expected, opts) when is_function(trigger_fun, 1) and is_list(opts) do
    with_dialog(session, expected, trigger_fun, opts)
  end

  def with_popup(session, trigger_fun, callback_fun, opts \\ []) do
    Browser.with_popup(ensure_session(session), trigger_fun, callback_fun, opts)
  end

  def screenshot(session, opts_or_path \\ []), do: Browser.screenshot(ensure_session(session), opts_or_path)
  def type(session, text, opts \\ []), do: Browser.type(ensure_session(session), text, opts)
  def press(session, key, opts \\ []), do: Browser.press(ensure_session(session), key, opts)

  def drag(session, source_selector, target_selector, opts \\ []),
    do: Browser.drag(ensure_session(session), source_selector, target_selector, opts)

  def cookies(session), do: Browser.cookies(ensure_session(session))
  def cookie(session, name), do: Browser.cookie(ensure_session(session), name)
  def session_cookie(session), do: Browser.session_cookie(ensure_session(session))
  def add_cookie(session, name, value, opts \\ []), do: Browser.add_cookie(ensure_session(session), name, value, opts)

  defmodule Assertions do
    @moduledoc """
    `PhoenixTest.Assertions`-style aliases for assertion calls.
    """

    defdelegate assert_has(session, selector), to: Cerberus.PhoenixTestShim

    def assert_has(session, selector, opts) when is_list(opts),
      do: Cerberus.PhoenixTestShim.assert_has(session, selector, opts)

    def assert_has(session, selector, text), do: Cerberus.PhoenixTestShim.assert_has(session, selector, text)

    def assert_has(session, selector, text, opts) when is_list(opts),
      do: Cerberus.PhoenixTestShim.assert_has(session, selector, text, opts)

    defdelegate refute_has(session, selector), to: Cerberus.PhoenixTestShim

    def refute_has(session, selector, opts) when is_list(opts),
      do: Cerberus.PhoenixTestShim.refute_has(session, selector, opts)

    def refute_has(session, selector, text), do: Cerberus.PhoenixTestShim.refute_has(session, selector, text)

    def refute_has(session, selector, text, opts) when is_list(opts),
      do: Cerberus.PhoenixTestShim.refute_has(session, selector, text, opts)

    defdelegate assert_path(session, expected), to: Cerberus.PhoenixTestShim
    defdelegate assert_path(session, expected, opts), to: Cerberus.PhoenixTestShim
    defdelegate refute_path(session, expected), to: Cerberus.PhoenixTestShim
    defdelegate refute_path(session, expected, opts), to: Cerberus.PhoenixTestShim
  end

  defmodule TestHelpers do
    @moduledoc """
    Helpers available in PhoenixTest-style test suites.
    """

    @doc """
    Converts a multi-line string into a whitespace-forgiving regex.
    """
    def ignore_whitespace(string) do
      string
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map_join("\n", fn s -> "\\s*" <> s <> "\\s*" end)
      |> Regex.compile!([:dotall])
    end
  end

  defp normalize_select_opts(opts) do
    {option, opts} =
      opts
      |> Keyword.fetch!(:option)
      |> then(&{&1, opts |> Keyword.delete(:option) |> Keyword.delete(:exact)})

    exact_option = Keyword.get(opts, :exact_option, true)
    Keyword.put(opts, :option, normalize_option(option, exact_option))
  end

  defp normalize_option(list, exact_option) when is_list(list), do: Enum.map(list, &normalize_option(&1, exact_option))

  defp normalize_option(value, exact_option)
       when is_binary(value) or is_struct(value, Regex) or is_atom(value) or is_number(value) do
    Cerberus.text(normalize_scalar(value), exact: exact_option)
  end

  defp normalize_option(value, _exact_option), do: value

  defp field_locator(field_or_selector, opts) do
    if selector_string?(field_or_selector) do
      Cerberus.css(field_or_selector)
    else
      Cerberus.label(normalize_scalar(field_or_selector), exact: Keyword.get(opts, :exact, true))
    end
  end

  defp click_locator(target, opts) do
    cond do
      selector_string?(target) ->
        Cerberus.css(target)

      is_struct(target, Locator) ->
        target

      true ->
        Cerberus.text(normalize_scalar(target), exact: Keyword.get(opts, :exact, false))
    end
  end

  defp normalize_selector(selector) when is_binary(selector), do: Cerberus.css(selector)
  defp normalize_selector(selector), do: selector

  defp normalize_assert_request(selector, opts) do
    opts = normalize_match_opts(opts)
    exact = Keyword.get(opts, :exact, false)
    locator = normalize_selector(selector)

    locator =
      case Keyword.fetch(opts, :text) do
        {:ok, value} -> Cerberus.and_(locator, Cerberus.text(value, exact_opt(value, exact)))
        :error -> locator
      end

    locator =
      case Keyword.fetch(opts, :value) do
        {:ok, value} -> Cerberus.and_(locator, Cerberus.text(value, exact_opt(value, exact)))
        :error -> locator
      end

    locator =
      case Keyword.fetch(opts, :label) do
        {:ok, value} -> Cerberus.and_(locator, Cerberus.label(value, exact_opt(value, exact)))
        :error -> locator
      end

    {locator, Keyword.drop(opts, [:text, :value, :label, :exact])}
  end

  defp normalize_match_opts(opts) do
    opts
    |> maybe_update(:text, &normalize_scalar/1)
    |> maybe_update(:value, &normalize_scalar/1)
    |> maybe_update(:label, &normalize_scalar/1)
  end

  defp maybe_update(opts, key, fun) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> Keyword.put(opts, key, fun.(value))
      :error -> opts
    end
  end

  defp normalize_path_opts(opts) when is_list(opts) do
    if Keyword.has_key?(opts, :query_params) and not Keyword.has_key?(opts, :query) do
      opts
      |> Keyword.put(:query, Keyword.fetch!(opts, :query_params))
      |> Keyword.delete(:query_params)
    else
      opts
    end
  end

  defp ensure_session(%Plug.Conn{} = conn), do: Cerberus.session(conn)
  defp ensure_session(session), do: session

  defp dialog_text_locator(%Locator{} = locator), do: locator
  defp dialog_text_locator(value) when is_struct(value, Regex), do: Cerberus.text(value)
  defp dialog_text_locator(value), do: Cerberus.text(normalize_scalar(value), exact: false)

  defp normalize_scalar(value) when is_binary(value) or is_struct(value, Regex), do: value

  defp normalize_scalar(value) do
    case Safe.impl_for(value) do
      nil -> to_string(value)
      _impl -> value |> Safe.to_iodata() |> IO.iodata_to_binary()
    end
  end

  defp exact_opt(value, _exact) when is_struct(value, Regex), do: []
  defp exact_opt(_value, exact), do: [exact: exact]

  defp selector_string?(value) when not is_binary(value), do: false

  defp selector_string?(value) do
    String.starts_with?(value, ["#", ".", "[", "*"]) or String.contains?(value, ["[", "#", ">", "="])
  end

  defp resolve_upload_path(path) do
    cond do
      File.exists?(path) ->
        path

      String.starts_with?(path, "test/files/") and
          File.exists?(String.replace_prefix(path, "test/files/", "test/support/files/")) ->
        String.replace_prefix(path, "test/files/", "test/support/files/")

      true ->
        path
    end
  end
end
