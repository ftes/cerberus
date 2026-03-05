defmodule Cerberus.TestSupport.PhoenixTestPlaywright.Html do
  @moduledoc false

  def element(html) when is_binary(html) do
    html
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
