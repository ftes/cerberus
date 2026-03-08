defmodule Cerberus.TestSupport.PhoenixTestPlaywright.Legacy do
  @moduledoc false

  import ExUnit.Assertions

  alias Cerberus.TestSupport.PhoenixTestPlaywright.Driver
  alias Cerberus.TestSupport.PhoenixTestPlaywright.Live
  alias Phoenix.HTML.Safe
  alias Plug.Conn.Query

  @prefix "/phoenix_test/playwright"

  def visit(session_or_conn, path), do: Cerberus.visit(ensure_session(session_or_conn), prefix_path(path))

  def reload_page(session), do: Cerberus.reload_page(ensure_session(session))

  def current_path(session), do: session |> ensure_session() |> then(& &1.current_path) |> strip_prefix()

  def assert_has(session, "title") do
    session = ensure_session(session)
    title = Driver.render_page_title(session)

    assert is_binary(title) and title != "",
           "Expected title to be present but could not find it."

    session
  end

  def assert_has(session, selector) do
    {locator, opts} = normalize_assert_request(selector, [])
    Cerberus.assert_has(ensure_session(session), locator, opts)
  end

  def assert_has(session, "title", opts) when is_list(opts) do
    session = ensure_session(session)
    opts = normalize_match_opts(opts)

    if Keyword.has_key?(opts, :text) do
      title = Driver.render_page_title(session)
      expected = Keyword.fetch!(opts, :text)
      exact = Keyword.get(opts, :exact, false)

      assert title_matches?(title, expected, exact),
             "Expected title to be #{inspect(expected)} but got #{inspect(title)}"
    else
      assert_has(session, "title")
    end

    session
  end

  def assert_has(session, selector, opts) when is_list(opts) do
    if is_binary(selector) and value_label_assertion?(opts) do
      return_assert_value_label(ensure_session(session), selector, normalize_match_opts(opts))
    else
      {locator, normalized_opts} = normalize_assert_request(selector, opts)
      Cerberus.assert_has(ensure_session(session), locator, normalized_opts)
    end
  end

  def assert_has(session, selector, text), do: assert_has(session, selector, text: normalize_scalar(text))

  def assert_has(session, selector, text, opts) when is_list(opts) do
    if Keyword.has_key?(opts, :text) do
      raise ArgumentError, text_arg_conflict_message(:assert_has, selector, text, opts)
    end

    assert_has(session, selector, Keyword.put(opts, :text, normalize_scalar(text)))
  end

  def refute_has(session, "title") do
    session = ensure_session(session)
    title = Driver.render_page_title(session)

    assert is_nil(title), "Expected title not to be present but found: #{inspect(title)}"

    session
  end

  def refute_has(session, selector) do
    {locator, opts} = normalize_assert_request(selector, [])
    Cerberus.refute_has(ensure_session(session), locator, opts)
  end

  def refute_has(session, "title", opts) when is_list(opts) do
    session = ensure_session(session)
    opts = normalize_match_opts(opts)

    if Keyword.has_key?(opts, :text) do
      title = Driver.render_page_title(session)
      expected = Keyword.fetch!(opts, :text)
      exact = Keyword.get(opts, :exact, false)

      refute title_matches?(title, expected, exact), "Expected title not to be #{inspect(expected)}"
    else
      refute_has(session, "title")
    end

    session
  end

  def refute_has(session, selector, opts) when is_list(opts) do
    if is_binary(selector) and value_label_assertion?(opts) do
      return_refute_value_label(ensure_session(session), selector, normalize_match_opts(opts))
    else
      {locator, normalized_opts} = normalize_assert_request(selector, opts)
      Cerberus.refute_has(ensure_session(session), locator, normalized_opts)
    end
  end

  def refute_has(session, selector, text), do: refute_has(session, selector, text: normalize_scalar(text))

  def refute_has(session, selector, text, opts) when is_list(opts) do
    if Keyword.has_key?(opts, :text) do
      raise ArgumentError, text_arg_conflict_message(:refute_has, selector, text, opts)
    end

    refute_has(session, selector, Keyword.put(opts, :text, normalize_scalar(text)))
  end

  def assert_path(session, expected, opts \\ [])

  def assert_path(%Live{} = session, expected, opts), do: assert_inline_path(session, expected, opts)

  def assert_path(session, expected, opts) do
    Cerberus.assert_path(ensure_session(session), prefix_path(expected), opts)
  end

  def refute_path(session, expected, opts \\ [])

  def refute_path(%Live{} = session, expected, opts), do: refute_inline_path(session, expected, opts)

  def refute_path(session, expected, opts) do
    Cerberus.refute_path(ensure_session(session), prefix_path(expected), opts)
  end

  def click(session, selector) when is_binary(selector) do
    Cerberus.click(ensure_session(session), normalize_click_selector(selector))
  end

  def click(session, selector, text) when is_binary(selector) and not is_list(text) do
    locator =
      selector
      |> normalize_click_selector()
      |> Cerberus.and_(Cerberus.text(normalize_scalar(text), exact: false))

    Cerberus.click(ensure_session(session), locator)
  end

  def click(session, selector, opts) when is_binary(selector) and is_list(opts) do
    locator = normalize_click_selector(selector)
    Cerberus.click(ensure_session(session), locator, opts)
  end

  def click_link(session, text) when not is_list(text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.role(:link, name: normalize_scalar(text), exact: false))
  end

  def click_link(session, text, opts) when is_list(opts) do
    exact = Keyword.get(opts, :exact, false)
    action_opts = Keyword.delete(opts, :exact)

    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.role(:link, name: normalize_scalar(text), exact: exact), action_opts)
  end

  def click_link(session, selector, text) when not is_list(text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.role(Cerberus.css(selector), :link, name: normalize_scalar(text), exact: false))
  end

  def click_link(session, selector, text, opts) when is_list(opts) do
    exact = Keyword.get(opts, :exact, false)
    action_opts = Keyword.delete(opts, :exact)

    session
    |> ensure_session()
    |> Cerberus.click(
      Cerberus.role(Cerberus.css(selector), :link, name: normalize_scalar(text), exact: exact),
      action_opts
    )
  end

  def click_button(session, text) when not is_list(text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.role(:button, name: normalize_scalar(text), exact: false))
  end

  def click_button(session, text, opts) when is_list(opts) do
    exact = Keyword.get(opts, :exact, false)
    action_opts = Keyword.delete(opts, :exact)

    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.role(:button, name: normalize_scalar(text), exact: exact), action_opts)
  end

  def click_button(session, selector, text) when not is_list(text) do
    session
    |> ensure_session()
    |> Cerberus.click(Cerberus.role(Cerberus.css(selector), :button, name: normalize_scalar(text), exact: false))
  end

  def click_button(session, selector, text, opts) when is_list(opts) do
    exact = Keyword.get(opts, :exact, false)
    action_opts = Keyword.delete(opts, :exact)

    session
    |> ensure_session()
    |> Cerberus.click(
      Cerberus.role(Cerberus.css(selector), :button, name: normalize_scalar(text), exact: exact),
      action_opts
    )
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
    |> Cerberus.submit(Cerberus.role(:button, name: normalize_scalar(text), exact: false))
  end

  def within(session, selector, callback) when is_function(callback, 1) do
    scoped_locator = if is_binary(selector), do: Cerberus.css(selector), else: selector
    Cerberus.within(ensure_session(session), scoped_locator, callback)
  end

  def open_browser(session), do: Cerberus.open_browser(ensure_session(session))
  def open_browser(session, open_fun), do: Cerberus.open_browser(ensure_session(session), open_fun)

  def unwrap(session, callback) when is_function(callback, 1), do: Cerberus.unwrap(ensure_session(session), callback)

  defp assert_inline_path(%Live{current_path: current_path}, expected, opts) do
    {actual_path, actual_query} = split_path(current_path)
    {expected_path, _expected_query_from_path} = split_path(expected)

    assert wildcard_path_match?(actual_path, expected_path),
           "Expected current path #{inspect(current_path)} to match #{inspect(expected)}"

    if Keyword.has_key?(opts, :query_params) do
      expected_query = opts |> Keyword.fetch!(:query_params) |> normalize_query_map()

      assert actual_query == expected_query,
             "Expected query params #{inspect(expected_query)} but got #{inspect(actual_query)}"
    end

    %Live{current_path: current_path}
  end

  defp refute_inline_path(%Live{current_path: current_path}, expected, opts) do
    {actual_path, actual_query} = split_path(current_path)
    {expected_path, _expected_query_from_path} = split_path(expected)

    path_match? = wildcard_path_match?(actual_path, expected_path)

    query_match? =
      if Keyword.has_key?(opts, :query_params) do
        expected_query = opts |> Keyword.fetch!(:query_params) |> normalize_query_map()
        actual_query == expected_query
      else
        true
      end

    refute path_match? and query_match?,
           "Expected current path #{inspect(current_path)} to NOT match #{inspect(expected)}"

    %Live{current_path: current_path}
  end

  defp split_path(path) when is_binary(path) do
    uri = URI.parse(path)
    query = if is_binary(uri.query), do: Query.decode(uri.query), else: %{}
    {uri.path || "/", normalize_query_map(query)}
  end

  defp wildcard_path_match?(actual_path, expected_path) do
    regex =
      expected_path
      |> Regex.escape()
      |> String.replace("\\*", "[^/]+")
      |> then(&Regex.compile!("^" <> &1 <> "$"))

    Regex.match?(regex, actual_path)
  end

  defp normalize_query_map(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), normalize_query_value(value)} end)
  end

  defp normalize_query_value(map) when is_map(map), do: normalize_query_map(map)
  defp normalize_query_value(list) when is_list(list), do: Enum.map(list, &normalize_query_value/1)
  defp normalize_query_value(value) when is_binary(value), do: value
  defp normalize_query_value(value), do: to_string(value)

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

  defp normalize_selector(selector) when is_binary(selector), do: Cerberus.css(selector)
  defp normalize_selector(selector), do: selector

  defp normalize_click_selector("internal:label=\"" <> rest) do
    if String.ends_with?(rest, "\"") do
      quoted = String.trim_trailing(rest, "\"")
      Cerberus.label(quoted, exact: true)
    else
      Cerberus.css("internal:label=\"" <> rest)
    end
  end

  defp normalize_click_selector(selector), do: Cerberus.css(selector)

  defp normalize_assert_request(selector, opts) do
    opts = normalize_match_opts(opts)
    validate_assert_match_opts!(opts)
    {selector, opts} = normalize_at_selector(selector, opts)
    {selector, opts} = normalize_value_selector(selector, opts)
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

    {locator, Keyword.drop(opts, [:text, :value, :label, :exact, :at])}
  end

  defp return_assert_value_label(session, selector, opts) do
    value = Keyword.fetch!(opts, :value)
    label = Keyword.fetch!(opts, :label)
    value_selector = "#{selector}[value=#{inspect(value)}]"
    value_opts = Keyword.drop(opts, [:label, :value, :exact])
    label_opts = label_assertion_opts(opts, label)

    if assertion_matches?(session, value_selector, value_opts) and assertion_matches?(session, "label", label_opts) do
      session
    else
      raise ExUnit.AssertionError,
        message:
          "Could not find #{count_elements(Keyword.get(opts, :count, :any))} with selector #{inspect(selector)} and value #{inspect(value)} with label #{inspect(label)}"
    end
  end

  defp return_refute_value_label(session, selector, opts) do
    value = Keyword.fetch!(opts, :value)
    label = Keyword.fetch!(opts, :label)
    value_selector = "#{selector}[value=#{inspect(value)}]"
    value_opts = Keyword.drop(opts, [:label, :value, :exact])
    label_opts = label_assertion_opts(opts, label)

    if assertion_matches?(session, value_selector, value_opts) and assertion_matches?(session, "label", label_opts) do
      raise ExUnit.AssertionError,
        message:
          "Expected not to find #{count_elements(Keyword.get(opts, :count, :any))} with selector #{inspect(selector)} and value #{inspect(value)} with label #{inspect(label)}"
    else
      session
    end
  end

  defp label_assertion_opts(opts, label) do
    opts =
      opts
      |> Keyword.drop([:value, :label, :exact])
      |> Keyword.put(:text, label)

    case Keyword.fetch(opts, :count) do
      {:ok, :any} -> Keyword.delete(opts, :count)
      _ -> opts
    end
  end

  defp assertion_matches?(session, selector, opts) do
    session = ensure_session(session)

    try do
      {locator, normalized_opts} = normalize_assert_request(selector, opts)
      _ = Cerberus.assert_has(session, locator, normalized_opts)
      true
    rescue
      ExUnit.AssertionError -> false
    end
  end

  defp value_label_assertion?(opts) when is_list(opts) do
    Keyword.has_key?(opts, :value) and Keyword.has_key?(opts, :label)
  end

  defp validate_assert_match_opts!(opts) do
    if Keyword.has_key?(opts, :text) and Keyword.has_key?(opts, :value) do
      raise ArgumentError, "Cannot provide both :text and :value to assertions"
    end
  end

  defp normalize_at_selector(selector, opts) do
    case Keyword.fetch(opts, :at) do
      {:ok, at} ->
        at = normalize_at_option!(at)

        if is_binary(selector) do
          {"#{selector}:nth-child(#{at})", opts}
        else
          raise ArgumentError, ":at option requires a string CSS selector in PhoenixTest compatibility mode"
        end

      :error ->
        {selector, opts}
    end
  end

  defp normalize_value_selector(selector, opts) do
    case Keyword.fetch(opts, :value) do
      {:ok, value} when is_binary(selector) ->
        {"#{selector}[value=#{inspect(value)}]", Keyword.delete(opts, :value)}

      _ ->
        {selector, opts}
    end
  end

  defp count_elements(:any), do: "any elements"
  defp count_elements(1), do: "1 element"
  defp count_elements(count) when is_integer(count), do: "#{count} elements"
  defp count_elements(_), do: "elements"

  defp normalize_at_option!(at) when is_integer(at) and at > 0, do: at

  defp normalize_at_option!(at) do
    raise ArgumentError, ":at option requires a positive integer, got: #{inspect(at)}"
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

  defp ensure_session(%Plug.Conn{} = conn), do: Cerberus.session(conn)
  defp ensure_session(session), do: session

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

  defp prefix_path(path) when is_binary(path) do
    cond do
      String.starts_with?(path, ["http://", "https://"]) -> path
      String.starts_with?(path, @prefix <> "/") -> path
      path == @prefix -> path
      String.starts_with?(path, "/") -> @prefix <> path
      true -> @prefix <> "/" <> path
    end
  end

  defp strip_prefix(nil), do: nil

  defp strip_prefix(path) when is_binary(path) do
    cond do
      String.starts_with?(path, @prefix <> "/") -> String.replace_prefix(path, @prefix, "")
      path == @prefix -> "/"
      true -> path
    end
  end

  defp title_matches?(title, _expected, _exact) when title in [nil, ""], do: false

  defp title_matches?(title, expected, _exact) when is_struct(expected, Regex) do
    Regex.match?(expected, title)
  end

  defp title_matches?(title, expected, true), do: title == expected
  defp title_matches?(title, expected, false), do: title =~ expected

  defp text_arg_conflict_message(fun, selector, text, opts) do
    normalized_text = normalize_scalar(text)
    suggested_opts = Keyword.delete(opts, :text)

    suggested_call =
      if suggested_opts == [] do
        "#{fun}(session, #{inspect(selector)}, #{inspect(normalized_text)})"
      else
        "#{fun}(session, #{inspect(selector)}, #{inspect(normalized_text)}, #{inspect(suggested_opts)})"
      end

    "Cannot specify `text` as the third argument and `:text` as an option.\n\n" <>
      "You might want to change it to:\n\n#{suggested_call}\n"
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
