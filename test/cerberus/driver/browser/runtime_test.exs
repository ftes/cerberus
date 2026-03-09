defmodule Cerberus.Driver.Browser.RuntimeTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Fixtures.Endpoint

  setup do
    browser_config = Application.get_env(:cerberus, :browser, [])

    on_exit(fn ->
      Application.put_env(:cerberus, :browser, browser_config)
    end)

    :ok
  end

  describe "headless?/2" do
    test "defaults to headless" do
      assert Runtime.headless?([], []) == true
    end

    test "headless=false disables headless mode" do
      assert Runtime.headless?([], headless: false) == false
    end

    test "explicit headless option overrides merged config" do
      assert Runtime.headless?([headless: true], headless: false) == true
      assert Runtime.headless?([headless: false], headless: true) == false
    end
  end

  describe "slow_mo_ms/1" do
    test "defaults to zero and supports top-level/session overrides" do
      Application.put_env(:cerberus, :browser, slow_mo: 40)

      assert Runtime.slow_mo_ms([]) == 40
      assert Runtime.slow_mo_ms(slow_mo: 120) == 120
    end

    test "supports nested browser overrides" do
      Application.put_env(:cerberus, :browser, slow_mo: 40)

      assert Runtime.slow_mo_ms(browser: [slow_mo: 75]) == 75
    end
  end

  describe "browser_name/1" do
    test "always resolves the firefox browser lane" do
      assert Runtime.browser_name([]) == :firefox
      assert Runtime.browser_name(browser_name: :firefox) == :firefox
      assert Runtime.browser_name(browser: [browser_name: :firefox]) == :firefox
    end

    test "rejects non-firefox browser names" do
      assert_raise ArgumentError, ~r/browser_name must be :firefox/, fn ->
        Runtime.browser_name(browser_name: :chrome)
      end
    end
  end

  describe "resolve_base_url/1" do
    test "prefers explicit base_url option over configured values" do
      assert Runtime.resolve_base_url(base_url: "http://session-override:7777") == "http://session-override:7777"
    end

    test "falls back to endpoint url when :base_url is unset" do
      previous_base_url = Application.get_env(:cerberus, :base_url)
      previous_endpoint = Application.get_env(:cerberus, :endpoint)

      on_exit(fn ->
        if is_nil(previous_base_url) do
          Application.delete_env(:cerberus, :base_url)
        else
          Application.put_env(:cerberus, :base_url, previous_base_url)
        end

        if is_nil(previous_endpoint) do
          Application.delete_env(:cerberus, :endpoint)
        else
          Application.put_env(:cerberus, :endpoint, previous_endpoint)
        end
      end)

      Application.delete_env(:cerberus, :base_url)
      Application.put_env(:cerberus, :endpoint, Endpoint)

      assert Runtime.resolve_base_url([]) == Endpoint.url()
    end
  end
end
