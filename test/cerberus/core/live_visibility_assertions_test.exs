defmodule Cerberus.CoreLiveVisibilityAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :live

  test "live assertions support visible filters", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/counter")
      |> refute_has(text("Hidden live helper text"), visible: true)
      |> assert_has(text("Hidden live helper text"), visible: false)
      |> assert_has(text("Hidden live helper text"), visible: :any)
    end)
  end
end
