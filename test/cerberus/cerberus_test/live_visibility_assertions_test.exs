defmodule CerberusTest.LiveVisibilityAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "live assertions support visible filters" do
    :phoenix
    |> session()
    |> visit("/live/counter")
    |> refute_has(text("Hidden live helper text"), visible: true)
    |> assert_has(text("Hidden live helper text"), visible: false)
    |> assert_has(text("Hidden live helper text"), visible: :any)
  end
end
