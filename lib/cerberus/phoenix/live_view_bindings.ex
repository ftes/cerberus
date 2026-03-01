defmodule Cerberus.LiveViewBindings do
  @moduledoc false

  @valid_js_commands MapSet.new(["navigate", "patch", "push"])

  @spec phx_click?(term()) :: boolean()
  def phx_click?(value) when is_binary(value) do
    value = String.trim(value)

    cond do
      value == "" ->
        false

      String.starts_with?(value, "[") ->
        value
        |> decode_js_commands()
        |> any_valid_js_command?()

      true ->
        true
    end
  end

  def phx_click?(_value), do: false

  @spec dispatch_change?(term()) :: boolean()
  def dispatch_change?(value) when is_binary(value) do
    value = String.trim(value)

    if String.starts_with?(value, "[") do
      value
      |> decode_js_commands()
      |> Enum.any?(&dispatch_change_command?/1)
    else
      false
    end
  end

  def dispatch_change?(_value), do: false

  defp decode_js_commands(value) do
    case Jason.decode(value) do
      {:ok, commands} when is_list(commands) -> commands
      _ -> []
    end
  end

  defp any_valid_js_command?(commands) do
    Enum.any?(commands, &valid_js_command?/1)
  end

  defp valid_js_command?([command, _opts]) when is_binary(command) do
    MapSet.member?(@valid_js_commands, command)
  end

  defp valid_js_command?(_command), do: false

  defp dispatch_change_command?(["dispatch", %{} = opts]) do
    case Map.get(opts, "event") do
      "change" -> true
      _ -> false
    end
  end

  defp dispatch_change_command?(_command), do: false
end
