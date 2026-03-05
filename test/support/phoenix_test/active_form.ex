defmodule Cerberus.TestSupport.PhoenixTest.ActiveForm do
  @moduledoc false

  def active?(value), do: not is_nil(value)
end
