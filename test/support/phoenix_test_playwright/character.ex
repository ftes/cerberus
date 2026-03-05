defmodule Cerberus.TestSupport.PhoenixTestPlaywright.Character do
  @moduledoc false

  defstruct [:name]

  defimpl Phoenix.HTML.Safe do
    alias Cerberus.TestSupport.PhoenixTestPlaywright.Character

    def to_iodata(%Character{} = character), do: character.name
  end
end
