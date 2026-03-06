defmodule Cerberus.Driver.Static.FormData do
  @moduledoc false

  alias Cerberus.Html
  alias Cerberus.Session
  alias Plug.Conn.Query

  @spec put_form_value(map(), String.t() | nil, String.t(), term()) :: map()
  def put_form_value(form_data, form, name, value) do
    put_form_value(form_data, form, nil, name, value)
  end

  @spec put_form_value(map(), String.t() | nil, String.t() | nil, String.t(), term()) :: map()
  def put_form_value(form_data, form, form_selector, name, value) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, form_selector, active_form)
    form_values = Map.get(values, key, %{})
    next_values = Map.put(values, key, Map.put(form_values, name, value))

    %{
      active_form: key,
      active_form_selector: submit_form_selector(%{form: form, form_selector: form_selector}),
      values: next_values
    }
  end

  @spec submit_form_selector(map()) :: String.t() | nil
  def submit_form_selector(%{form_selector: selector}) when is_binary(selector) and selector != "", do: selector

  def submit_form_selector(%{form: form}) when is_binary(form) and form != "" do
    ~s(form[id="#{form}"])
  end

  def submit_form_selector(_), do: nil

  @spec params_for_submit(struct(), map(), String.t() | nil) :: map()
  def params_for_submit(session, button, form_selector) do
    params = submit_form_payload(session, button, form_selector)

    case button_payload(button) do
      nil -> params
      {name, value} -> Map.put(params, name, value)
    end
  end

  @spec decode_query_params(map()) :: map()
  def decode_query_params(params) when is_map(params) do
    {query_parts, replacements} =
      params
      |> expand_query_entries()
      |> Enum.with_index()
      |> Enum.map_reduce(%{}, fn {{name, value}, index}, acc ->
        marker = "__cerberus_param_#{index}__"
        part = "#{URI.encode_www_form(name)}=#{URI.encode_www_form(marker)}"
        {part, Map.put(acc, marker, value)}
      end)

    query_parts
    |> Enum.join("&")
    |> Query.decode()
    |> restore_query_values(replacements)
  end

  @spec clear_submitted_form(map(), String.t() | nil) :: map()
  def clear_submitted_form(form_data, form), do: clear_submitted_form(form_data, form, nil)

  @spec clear_submitted_form(map(), String.t() | nil, String.t() | nil) :: map()
  def clear_submitted_form(form_data, form, form_selector) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, form_selector, active_form)
    %{active_form: nil, active_form_selector: nil, values: Map.delete(values, key)}
  end

  @spec active_form_selector(map()) :: String.t() | nil
  def active_form_selector(form_data) do
    %{active_form: active_form} = normalized = normalize_form_data(form_data)

    case Map.get(normalized, :active_form_selector) do
      selector when is_binary(selector) and selector != "" -> selector
      _ -> selector_from_key(active_form)
    end
  end

  @spec toggled_checkbox_value(struct(), map(), boolean()) :: term()
  def toggled_checkbox_value(session, field, checked?) do
    name = field.name
    defaults = submit_defaults_for_field(session, field)
    active = pruned_params_for_form(session, field.form, field[:form_selector])
    current = Map.get(active, name, Map.get(defaults, name))
    input_value = field[:input_value] || "on"
    hidden_unchecked_value = checkbox_hidden_unchecked_value(session, field)

    if String.ends_with?(name, "[]") do
      current_list = checkbox_value_list(current)

      if checked? do
        ensure_checkbox_value(current_list, input_value)
      else
        Enum.reject(current_list, &(&1 == input_value))
      end
    else
      if checked? do
        input_value
      else
        checkbox_unchecked_value(defaults, name, input_value, hidden_unchecked_value)
      end
    end
  end

  @spec select_value_for_update(struct(), map(), term(), [String.t()], boolean()) :: term()
  def select_value_for_update(_session, _field, _option, values, false) do
    List.first(values)
  end

  def select_value_for_update(_session, _field, _option, values, true) do
    values
  end

  @spec upload_value_for_update(struct(), map(), map(), String.t()) :: term()
  def upload_value_for_update(session, field, file, source_path) do
    upload = %Plug.Upload{
      path: source_path,
      filename: file.file_name,
      content_type: file.mime_type
    }

    if String.ends_with?(field.name, "[]") do
      defaults = submit_defaults_for_field(session, field)
      active = pruned_params_for_form(session, field.form, field[:form_selector])
      current = Map.get(active, field.name, Map.get(defaults, field.name))
      checkbox_value_list(current) ++ [upload]
    else
      upload
    end
  end

  defp submit_form_payload(session, button, form_selector) do
    defaults = submit_form_defaults(session, button, form_selector)
    active = pruned_params_for_form(session, button.form, form_selector)
    Map.merge(defaults, active)
  end

  defp submit_form_defaults(_session, _button, selector) when selector in [nil, ""], do: %{}

  defp submit_form_defaults(session, _button, selector) when is_binary(selector) do
    Html.form_defaults(session.html, selector, Session.scope(session))
  end

  @spec pruned_params_for_form(struct(), String.t() | nil, String.t() | nil) :: map()
  def pruned_params_for_form(session, form, form_selector) do
    active = params_for_form(session.form_data, form, form_selector)
    keep = form_field_name_allowlist(session, form_selector)
    prune_form_params(active, keep)
  end

  defp params_for_form(form_data, form, form_selector) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, form_selector, active_form)
    Map.get(values, key, %{})
  end

  defp submit_defaults_for_field(session, field) do
    case field[:form_selector] do
      selector when is_binary(selector) and selector != "" ->
        Html.form_defaults(session.html, selector, Session.scope(session))

      _ ->
        %{}
    end
  end

  defp checkbox_value_list(nil), do: []
  defp checkbox_value_list(value) when is_list(value), do: value
  defp checkbox_value_list(value), do: [value]

  defp ensure_checkbox_value(values, input_value) do
    if Enum.any?(values, &(&1 == input_value)) do
      values
    else
      values ++ [input_value]
    end
  end

  defp checkbox_unchecked_value(defaults, name, input_value, hidden_unchecked_value) do
    if is_binary(hidden_unchecked_value) do
      hidden_unchecked_value
    else
      case Map.get(defaults, name) do
        ^input_value -> ""
        nil -> ""
        other -> other
      end
    end
  end

  defp checkbox_hidden_unchecked_value(session, field) do
    form_selector = field[:form_selector]

    if is_binary(form_selector) and form_selector != "" do
      Html.checkbox_unchecked_value(session.html, form_selector, field.name, Session.scope(session))
    end
  end

  defp normalize_form_data(%{active_form: active_form, values: values} = data) when is_map(values) do
    selector = Map.get(data, :active_form_selector) || selector_from_key(active_form)
    Map.put(data, :active_form_selector, selector)
  end

  defp normalize_form_data(values) when is_map(values) do
    %{active_form: "__default__", active_form_selector: nil, values: %{"__default__" => values}}
  end

  defp normalize_form_data(_), do: %{active_form: nil, active_form_selector: nil, values: %{}}

  defp form_key(form, _form_selector, _active_form) when is_binary(form) and form != "", do: "form:" <> form

  defp form_key(_form, form_selector, _active_form) when is_binary(form_selector) and form_selector != "",
    do: "selector:" <> form_selector

  defp form_key(_form, _form_selector, active_form) when is_binary(active_form), do: active_form
  defp form_key(_form, _form_selector, _active_form), do: "__default__"

  defp selector_from_key("form:" <> form_id), do: ~s(form[id="#{form_id}"])
  defp selector_from_key("selector:" <> selector) when selector != "", do: selector
  defp selector_from_key(_), do: nil

  defp expand_query_entries(params) do
    Enum.flat_map(params, fn
      {name, value} when is_list(value) ->
        Enum.map(value, &{name, &1})

      {name, value} ->
        [{name, value}]
    end)
  end

  defp restore_query_values(%{} = value, replacements) do
    Map.new(value, fn {key, nested} -> {key, restore_query_values(nested, replacements)} end)
  end

  defp restore_query_values(values, replacements) when is_list(values) do
    Enum.map(values, &restore_query_values(&1, replacements))
  end

  defp restore_query_values(value, replacements) when is_binary(value) do
    Map.get(replacements, value, value)
  end

  defp restore_query_values(value, _replacements), do: value

  defp button_payload(button) do
    case {button.button_name, button.button_value} do
      {name, value} when is_binary(name) and name != "" -> {name, value || ""}
      _ -> nil
    end
  end

  defp form_field_name_allowlist(_session, selector) when selector in [nil, ""], do: nil

  defp form_field_name_allowlist(session, selector) do
    Html.form_field_names(session.html, selector, Session.scope(session))
  end

  defp prune_form_params(params, nil) when is_map(params), do: params
  defp prune_form_params(params, %MapSet{} = keep) when is_map(params), do: Map.take(params, MapSet.to_list(keep))
end
