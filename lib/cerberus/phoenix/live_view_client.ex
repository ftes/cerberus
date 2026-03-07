defmodule Cerberus.Phoenix.LiveViewClient do
  @moduledoc false

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
