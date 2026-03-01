defmodule Cerberus.Driver.Static.FormData do
  @moduledoc false

  alias Cerberus.Html
  alias Cerberus.Session

  @spec put_form_value(map(), String.t() | nil, String.t(), term()) :: map()
  def put_form_value(form_data, form, name, value) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
    form_values = Map.get(values, key, %{})
    next_values = Map.put(values, key, Map.put(form_values, name, value))
    %{active_form: key, values: next_values}
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

  @spec clear_submitted_form(map(), String.t() | nil) :: map()
  def clear_submitted_form(form_data, form) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
    %{active_form: nil, values: Map.delete(values, key)}
  end

  @spec toggled_checkbox_value(struct(), map(), boolean()) :: term()
  def toggled_checkbox_value(session, field, checked?) do
    name = field.name
    defaults = submit_defaults_for_field(session, field)
    active = pruned_params_for_form(session, field.form, field[:form_selector])
    current = Map.get(active, name, Map.get(defaults, name))
    input_value = field[:input_value] || "on"

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
        checkbox_unchecked_value(defaults, name, input_value)
      end
    end
  end

  @spec select_value_for_update(struct(), map(), term(), [String.t()], boolean()) :: term()
  def select_value_for_update(_session, _field, _option, values, false) do
    List.first(values)
  end

  def select_value_for_update(_session, _field, option, values, true) when is_list(option) do
    values
  end

  def select_value_for_update(session, field, _option, values, true) do
    defaults = submit_defaults_for_field(session, field)
    active = pruned_params_for_form(session, field.form, field[:form_selector])
    current = Map.get(active, field.name, Map.get(defaults, field.name))

    current
    |> checkbox_value_list()
    |> Enum.concat(values)
    |> Enum.uniq()
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

  defp pruned_params_for_form(session, form, form_selector) do
    active = params_for_form(session.form_data, form)
    keep = form_field_name_allowlist(session, form_selector)
    prune_form_params(active, keep)
  end

  defp params_for_form(form_data, form) do
    %{active_form: active_form, values: values} = normalize_form_data(form_data)
    key = form_key(form, active_form)
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

  defp checkbox_unchecked_value(defaults, name, input_value) do
    case Map.get(defaults, name) do
      ^input_value -> ""
      nil -> ""
      other -> other
    end
  end

  defp normalize_form_data(%{active_form: _active_form, values: values} = data) when is_map(values), do: data

  defp normalize_form_data(values) when is_map(values) do
    %{active_form: "__default__", values: %{"__default__" => values}}
  end

  defp normalize_form_data(_), do: %{active_form: nil, values: %{}}

  defp form_key(form, _active_form) when is_binary(form) and form != "", do: "form:" <> form
  defp form_key(_form, active_form) when is_binary(active_form), do: active_form
  defp form_key(_form, _active_form), do: "__default__"

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
