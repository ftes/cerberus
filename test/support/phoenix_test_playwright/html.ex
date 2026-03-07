defmodule Cerberus.TestSupport.PhoenixTestPlaywright.Html do
  @moduledoc false

  def element(%LazyHTML{} = document) do
    document
    |> LazyHTML.to_html()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
