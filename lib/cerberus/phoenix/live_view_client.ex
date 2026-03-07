defmodule Cerberus.Phoenix.LiveViewClient do
  @moduledoc false

  alias Cerberus.OpenBrowser
  alias Phoenix.LiveView.Utils
  alias Phoenix.LiveViewTest.Element
  alias Phoenix.LiveViewTest.TreeDOM
  alias Phoenix.LiveViewTest.View

  @type view :: %View{}
  @type element :: %Element{}
  @type text_filter :: String.t() | Regex.t() | nil
  @type event_value_key :: String.t() | atom()
  @type event_value :: %{optional(event_value_key()) => term()} | [{event_value_key(), term()}]
  @type redirect_kind :: :redirect | :live_redirect
  @type redirect_opts :: %{required(:to) => String.t(), optional(atom()) => term()}
  @type render_result :: String.t() | {:error, {redirect_kind(), redirect_opts()}}
  @type html_tree :: term()
  @type html_snapshot :: {html_tree(), String.t() | nil}

  defguardp is_text_filter(text_filter)
            when is_binary(text_filter) or is_struct(text_filter, Regex) or is_nil(text_filter)

  @spec element(view(), String.t(), text_filter()) :: element()
  def element(%View{proxy: proxy}, selector, text_filter \\ nil)
      when is_binary(selector) and is_text_filter(text_filter) do
    %Element{proxy: proxy, selector: selector, text_filter: text_filter}
  end

  @spec form(view(), String.t(), event_value()) :: element()
  def form(%View{proxy: proxy}, selector, form_data \\ %{}) when is_binary(selector) do
    %Element{proxy: proxy, selector: selector, form_data: form_data}
  end

  @spec render(view() | element()) :: render_result()
  def render(view_or_element) do
    case render_tree(view_or_element) do
      {:error, reason} -> {:error, reason}
      html -> TreeDOM.to_html(html)
    end
  end

  @spec render_click(element(), event_value()) :: render_result()
  def render_click(%Element{} = element, value \\ %{}) when is_map(value) or is_list(value) do
    render_event(element, :click, value)
  end

  @spec render_change(element(), event_value()) :: render_result()
  def render_change(%Element{} = element, value \\ %{}) when is_map(value) or is_list(value) do
    render_event(element, :change, value)
  end

  @spec render_submit(element(), event_value()) :: render_result()
  def render_submit(%Element{} = element, value \\ %{}) when is_map(value) or is_list(value) do
    render_event(element, :submit, value)
  end

  @spec html(view() | element()) :: html_snapshot()
  def html(view_or_element) do
    call(view_or_element, :html)
  end

  @spec html_tree(view() | element()) :: {:ok, html_tree()} | :error
  def html_tree(view_or_element) do
    {tree, _static_path} = html(view_or_element)
    {:ok, tree}
  catch
    :exit, _ -> :error
  end

  @spec html_document(view() | element()) :: {:ok, LazyHTML.t()} | :error
  def html_document(view_or_element) do
    case html_tree(view_or_element) do
      {:ok, tree} -> {:ok, LazyHTML.from_tree(List.wrap(tree))}
      :error -> :error
    end
  end

  @spec live_children(view()) :: [view()]
  def live_children(%View{} = parent) do
    call(parent, {:live_children, proxy_topic(parent)})
  end

  @spec find_live_child(view(), String.t()) :: view() | nil
  def find_live_child(%View{} = parent, child_id) when is_binary(child_id) do
    parent
    |> live_children()
    |> Enum.find(fn %View{id: id} -> id == child_id end)
  end

  @spec assert_redirect(view(), non_neg_integer()) :: {String.t(), map()}
  def assert_redirect(%View{} = view, timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout))
      when is_integer(timeout) do
    assert_navigation(view, :redirect, nil, timeout)
  end

  @spec assert_redirect(view(), String.t(), non_neg_integer()) :: map()
  def assert_redirect(%View{} = view, to, timeout) when is_binary(to) and is_integer(timeout) do
    {_path, flash} = assert_navigation(view, :redirect, to, timeout)
    flash
  end

  @spec open_browser(view() | element(), (String.t() -> any())) :: view() | element()
  def open_browser(view_or_element, open_fun \\ &OpenBrowser.open_with_system_cmd/1) when is_function(open_fun, 1) do
    document =
      case html_document(view_or_element) do
        {:ok, document} -> document
        :error -> LazyHTML.from_tree(List.wrap(render_tree(view_or_element)))
      end

    endpoint =
      case view_or_element do
        %{endpoint: endpoint} when is_atom(endpoint) -> endpoint
        _ -> nil
      end

    base_url =
      case html(view_or_element) do
        {_tree, static_path} when is_binary(static_path) -> static_path
        _ -> nil
      end

    view_or_element
    |> maybe_wrap_document(document)
    |> OpenBrowser.write_snapshot!(base_url, endpoint)
    |> open_fun.()

    view_or_element
  end

  defp render_event(%Element{} = element, type, value) do
    call(element, {:render_event, element, type, value})
  end

  defp render_tree(%View{} = view) do
    render_tree(view, {proxy_topic(view), "render", nil})
  end

  defp render_tree(%Element{} = element) do
    render_tree(element, element)
  end

  defp render_tree(view_or_element, topic_or_element) do
    call(view_or_element, {:render_element, :find_element, topic_or_element})
  end

  defp maybe_wrap_document(view_or_element, content) do
    {html_tree, _static_path} = html(view_or_element)
    wrap_live_document(content, html_tree)
  end

  defp wrap_live_document(content, html_tree) do
    full_document = LazyHTML.from_tree(List.wrap(html_tree))
    content_tree = LazyHTML.to_tree(content)
    content_root = List.first(content_tree)

    cond do
      match?({"html", _, _}, content_root) ->
        content

      match?(["true" | _], phx_main_attr(content_root)) ->
        full_document

      true ->
        LazyHTML.from_tree([
          {"html", [],
           [
             live_document_head(html_tree),
             {"body", [], content_tree}
           ]}
        ])
    end
  end

  defp phx_main_attr(nil), do: nil
  defp phx_main_attr(node), do: TreeDOM.attribute(node, "data-phx-main")

  defp live_document_head(html_tree) do
    case TreeDOM.filter(html_tree, fn node -> TreeDOM.tag(node) == "head" end) do
      [head] -> head
      _ -> {"head", [], []}
    end
  end

  defp assert_navigation(view, kind, to, timeout) do
    %{proxy: {ref, topic, _}, endpoint: endpoint} = view

    receive do
      {^ref, {^kind, ^topic, %{to: new_to} = opts}} when new_to == to or is_nil(to) ->
        {new_to, Utils.verify_flash(endpoint, opts[:flash])}
    after
      timeout ->
        if to do
          raise ExUnit.AssertionError,
            message: "expected #{inspect(view.module)} to #{kind} to #{inspect(to)}, but got none"
        else
          raise ExUnit.AssertionError,
            message: "expected #{inspect(view.module)} to #{kind}, but got none"
        end
    end
  end

  defp call(view_or_element, tuple) do
    GenServer.call(proxy_pid(view_or_element), tuple, :infinity)
  catch
    :exit, {{:shutdown, {kind, opts}}, _} when kind in [:redirect, :live_redirect] ->
      {:error, {kind, opts}}

    :exit, {{exception, stack}, _} ->
      exit({{exception, stack}, {__MODULE__, :call, [view_or_element]}})
  else
    :ok -> :ok
    {:ok, result} -> result
    {:raise, exception} -> raise exception
  end

  defp proxy_pid(%{proxy: {_ref, _topic, pid}}), do: pid
  defp proxy_topic(%{proxy: {_ref, topic, _pid}}), do: topic
end
