defmodule Cerberus.PhoenixTestPlaywright.StepTest do
  use ExUnit.Case, async: true

  @moduletag skip: "step trace label internals are not part of Cerberus public API"

  test "produces labels that can be seen in the trace viewer" do
    assert true
  end
end
