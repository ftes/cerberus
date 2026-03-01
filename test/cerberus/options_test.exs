defmodule Cerberus.OptionsTest do
  use ExUnit.Case, async: true

  alias Cerberus.Options

  test "validate_assert! rejects unknown position options" do
    assert_raise ArgumentError, ~r/unknown options \[:first\]/, fn ->
      Options.validate_assert!([first: true], "assert_has/3")
    end
  end

  test "validate_fill_in! enforces valid between bounds" do
    assert_raise ArgumentError, ~r/:between/, fn ->
      Options.validate_fill_in!(between: {2, 1})
    end

    assert_raise ArgumentError, ~r/:between/, fn ->
      Options.validate_fill_in!(between: 3..1//-1)
    end
  end

  test "validate_fill_in! enforces mutually exclusive position filters" do
    assert_raise ArgumentError, ~r/mutually exclusive/, fn ->
      Options.validate_fill_in!(first: true, nth: 2)
    end
  end
end
