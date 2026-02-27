defmodule CerberusTest do
  use ExUnit.Case, async: true

  test "module loads" do
    assert Code.ensure_loaded?(Cerberus)
  end
end
