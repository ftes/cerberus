defmodule Cerberus.Driver.Browser.RuntimeTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Browser.Runtime

  describe "headless?/2" do
    test "defaults to headless" do
      assert Runtime.headless?([], []) == true
    end

    test "show_browser=true disables headless by default" do
      assert Runtime.headless?([], show_browser: true) == false
    end

    test "explicit headless option overrides show_browser" do
      assert Runtime.headless?([headless: true], show_browser: true) == true
      assert Runtime.headless?([headless: false], show_browser: false) == false
    end
  end
end
