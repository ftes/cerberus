defmodule Cerberus.TestSupport.PhoenixTestPlaywright.ActiveForm do
  @moduledoc false

  def active?(value), do: not is_nil(value)
end
