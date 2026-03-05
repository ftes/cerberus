defmodule Cerberus.PhoenixTest.AssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus.TestSupport.PhoenixTest.Legacy

  alias Cerberus.TestSupport.PhoenixTest.Character
  alias Cerberus.TestSupport.PhoenixTest.Live
  alias ExUnit.AssertionError

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  defp assert_error_contains(error, expected_parts) do
    message = Exception.message(error)

    Enum.each(List.wrap(expected_parts), fn expected ->
      assert message =~ expected
    end)
  end

  describe "assert_has/2" do
    test "succeeds if single element is found with CSS selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("[data-role='title']")
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          assert_has(conn, "#nonexistent-id")
        end

      assert_error_contains(error, ["assert_has failed", "#nonexistent-id"])
    end

    test "succeeds if element searched is title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title")
    end

    test "succeeds if element searched is title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title")
    end

    test "succeeds if more than one element matches selector", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("li")
    end
  end

  describe "assert_has/3" do
    test "succeeds if single element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main page")
      |> assert_has("h1", "Main page")
      |> assert_has("#title", text: "Main page")
      |> assert_has("#title", "Main page")
      |> assert_has(".title", text: "Main page")
      |> assert_has(".title", "Main page")
      |> assert_has("[data-role='title']", text: "Main page")
      |> assert_has("[data-role='title']", "Main page")
    end

    test "succeeds if single element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
      |> assert_has("h1", "LiveView main page")
      |> assert_has("#title", text: "LiveView main page")
      |> assert_has("#title", "LiveView main page")
      |> assert_has(".title", text: "LiveView main page")
      |> assert_has(".title", "LiveView main page")
      |> assert_has("[data-role='title']", text: "LiveView main page")
      |> assert_has("[data-role='title']", "LiveView main page")
    end

    test "succeeds if more than one element matches selector but text narrows it down", %{
      conn: conn
    } do
      conn
      |> visit("/page/index")
      |> assert_has("li", text: "Aragorn")
      |> assert_has("li", "Aragorn")
      |> assert_has("li", "Aragorn", exact: false)
      |> assert_has("li", "Aragorn", exact: true)
    end

    test "succeeds if more than one element matches selector and text", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", text: "Multiple links")
      |> assert_has(".multiple_links", text: "Multiple links", count: 2)
      |> assert_has(".multiple_links", "Multiple links")
      |> assert_has(".multiple_links", "Multiple links", count: 2)
    end

    test "succeeds if text difference is only a matter of truncation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".has_extra_space", text: "Has extra space")
    end

    test "succeeds for non-binary text with Phoenix.HTML.Safe implementation", %{
      conn: conn
    } do
      aragorn = %Character{name: "Aragorn"}

      conn
      |> visit("/page/index")
      |> assert_has("li", text: aragorn)
      |> assert_has("li", aragorn)
      |> assert_has("li", aragorn, exact: false)
      |> assert_has("li", aragorn, exact: true)
    end

    test "succeeds when a non-200 status code is returned", %{conn: conn} do
      conn
      |> visit("/page/unauthorized")
      |> assert_has("h1", text: "Unauthorized")
    end

    test "succeeds when asserting by value", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", value: "Frodo")
    end

    test "succeeds when asserting by non-binary value with Phoenix.HTML.Safe implementation", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", value: %Character{name: "Frodo"})
    end

    test "succeeds when searching by value and implicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", label: "Hobbit", value: "Frodo")
    end

    test "succeeds when searching by value and explicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> assert_has("input", label: "Wizard", value: "Gandalf")
    end

    test "succeeds when selector matches either node with text, or any ancestor", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("label", text: "Country")
      |> assert_has("#country-form", text: "Country")
      |> assert_has("[data-phx-main]", text: "Country")
    end

    test "raises an error if value cannot be found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      error =
        assert_raise AssertionError, fn ->
          assert_has(session, "input", value: "does-not-exist")
        end

      assert_error_contains(error, ["assert_has failed", "input", "does-not-exist"])
    end

    test "raises an error if label and value are found more than expected", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      assert_has(session, "input", label: "Kingdoms", value: "Gondor")
      assert_has(session, "input", label: "Kingdoms", value: "Gondor", count: 2)

      error =
        assert_raise AssertionError, fn ->
          assert_has(session, "input", label: "Kingdoms", value: "Gondor", count: 1)
        end

      assert_error_contains(error, [~r/input/, "Gondor", "Kingdoms"])
    end

    test "raises an error if label (with value) cannot be found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      error =
        assert_raise AssertionError, fn ->
          assert_has(session, "input", label: "Halfling", value: "Frodo")
        end

      assert_error_contains(error, [~r/input/, "Frodo", "Halfling"])
    end

    test "raises an error if value (with label) cannot be found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      error =
        assert_raise AssertionError, fn ->
          assert_has(session, "input", label: "Hobbit", value: "Sam")
        end

      assert_error_contains(error, [~r/input/, "Sam", "Hobbit"])
    end

    test "raises if user provides :text and :value options", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      error =
        assert_raise ArgumentError, fn ->
          assert_has(session, "div", text: "some text", value: "some value")
        end

      assert_error_contains(error, ["text", "value"])
    end

    test "raises an error if the element cannot be found at all", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          assert_has(conn, "#nonexistent-id", text: "Main page")
        end

      assert_error_contains(error, ["assert_has failed", "#nonexistent-id", "Main page"])
    end

    test "raises error if element cannot be found but selector matches other elements", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          assert_has(conn, "h1", text: "Super page")
        end

      assert_error_contains(error, ["assert_has failed", "h1", "Super page", "expected text not found"])
    end

    test "can be used to assert on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
    end

    test "can be used to assert on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!")
    end

    test "can assert title's exactness", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("title", text: "PhoenixTest is the best!", exact: true)
    end

    test "raises if title does not match expected value (Static)", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> assert_has("title", text: "Not the title")
        end

      assert_error_contains(error, ["Expected title to be", "Not the title", "PhoenixTest is the best!"])
    end

    test "raises if title does not match expected value (Live)", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/live/index")
          |> assert_has("title", text: "Not the title")
        end

      assert_error_contains(error, ["Expected title to be", "Not the title", "PhoenixTest is the best!"])
    end

    test "raises if title is contained but is not exactly the same as expected (with exact=true)",
         %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> assert_has("title", text: "PhoenixTest", exact: true)
        end

      assert_error_contains(error, ["Expected title to be", "PhoenixTest", "PhoenixTest is the best!"])
    end

    test "raises error if element cannot be found and selector matches a nested structure", %{
      conn: conn
    } do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          assert_has(conn, "#multiple-items", text: "Frodo")
        end

      assert_error_contains(error, ["assert_has failed", "#multiple-items", "Frodo", "expected text not found"])
    end

    test "accepts a `count` option", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has(".multiple_links", count: 2)
      |> assert_has(".multiple_links", text: "Multiple links", count: 2)
      |> assert_has("h1", count: 1)
      |> assert_has("h1", text: "Main page", count: 1)
    end

    test "raises an error if count is more than expected count", %{conn: conn} do
      session = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          assert_has(session, ".multiple_links", count: 1)
        end

      assert_error_contains(error, [".multiple_links", "expected exactly 1", "got 2"])
    end

    test "raises an error if count is less than expected count", %{conn: conn} do
      session = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          assert_has(session, "h1", count: 2)
        end

      assert_error_contains(error, ["h1", "expected exactly 2", "got 1"])
    end

    test "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("h1", text: "Main", exact: false)
      |> assert_has("h1", text: "Main page", exact: true)
    end

    test "raises if `exact` text doesn't match", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> assert_has("h1", text: "Main", exact: true)
        end

      assert_error_contains(error, ["assert_has failed", "h1", "Main", "expected text not found"])
    end

    test "accepts an `at` option to assert on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> assert_has("#multiple-items li", at: 2, text: "Legolas")
    end

    test "raises if it cannot find element at `at` position", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> assert_has("#multiple-items li", at: 2, text: "Aragorn")
        end

      assert_error_contains(error, ["#multiple-items li:nth-child(2)", "Aragorn", "expected text not found"])
    end

    test "provides a clear error when trying to specify both text string arg and :text keyword arg", %{conn: conn} do
      session = visit(conn, "/page/index")

      error =
        assert_raise ArgumentError, fn ->
          assert_has(session, "h1", "Main page", text: "Other text", exact: true, count: 1)
        end

      assert_error_contains(error, ["Cannot specify", "text", ~s(assert_has(session, "h1", "Main page")])
    end
  end

  describe "refute_has/2" do
    test "succeeds if no element is found with CSS selector (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#some-invalid-id")
      |> refute_has("[data-role='invalid-role']")
    end

    test "succeeds if no element is found with CSS selector (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("#some-invalid-id")
      |> refute_has("[data-role='invalid-role']")
    end

    test "can refute presence of title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", "Not the title")
      |> refute_has("#something-else-to-test-pipe")
    end

    test "accepts a `count` option", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", count: 2)
      |> refute_has("h1", text: "Main page", count: 2)
      |> refute_has("h1", "Main page", count: 2)
      |> refute_has(".multiple_links", count: 1)
      |> refute_has(".multiple_links", text: "Multiple links", count: 1)
      |> refute_has(".multiple_links", "Multiple links", count: 1)
    end

    test "raises if element is found", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> refute_has("h1")
        end

      assert_error_contains(error, ["refute_has failed", "h1", "unexpected matching text found", "Main page"])
    end

    test "raises if title is found", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> refute_has("title")
        end

      assert_error_contains(error, ["title", "PhoenixTest is the best!"])
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          refute_has(conn, ".multiple_links")
        end

      assert_error_contains(error, [
        "refute_has failed",
        ".multiple_links",
        "unexpected matching text found",
        "Multiple links"
      ])
    end

    test "raises if there is one element and count is 1", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          refute_has(conn, "h1", count: 1)
        end

      assert_error_contains(error, [
        "refute_has failed",
        "h1",
        "unexpected matching text count satisfied constraints",
        "count: 1"
      ])
    end

    test "raises if there are the same number of elements as refuted", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error =
        assert_raise AssertionError, fn ->
          refute_has(conn, ".multiple_links", count: 2)
        end

      assert_error_contains(error, [
        "refute_has failed",
        ".multiple_links",
        "unexpected matching text count satisfied constraints",
        "count: 2"
      ])
    end
  end

  describe "refute_has/3" do
    test "can be used to refute on page title (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", "Not the title")
      |> refute_has("title", text: "Not this title either")
      |> refute_has("title", "Not this title either")
    end

    test "can be used to refute on page title (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", text: "Not the title")
      |> refute_has("title", "Not the title")
      |> refute_has("title", text: "Not this title either")
      |> refute_has("title", "Not this title either")
    end

    test "can be used to refute page title's exactness", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("title", text: "PhoenixTest is the", exact: true)
      |> refute_has("title", "PhoenixTest is the", exact: true)
    end

    test "raises if title matches value (Static)", %{conn: conn} do
      error1 =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> refute_has("title", text: "PhoenixTest is the best!")
        end

      assert_error_contains(error1, ["title", "PhoenixTest is the best!"])

      error2 =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> refute_has("title", "PhoenixTest is the best!")
        end

      assert_error_contains(error2, ["title", "PhoenixTest is the best!"])
    end

    test "raises if title matches value (Live)", %{conn: conn} do
      error1 =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/live/index")
          |> refute_has("title", text: "PhoenixTest is the best!")
        end

      assert_error_contains(error1, ["title", "PhoenixTest is the best!"])

      error2 =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/live/index")
          |> refute_has("title", "PhoenixTest is the best!")
        end

      assert_error_contains(error2, ["title", "PhoenixTest is the best!"])
    end

    test "succeeds if no element is found with CSS selector and text (Static)", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Not main page")
      |> refute_has("h1", "Not main page")
      |> refute_has("h2", text: "Main page")
      |> refute_has("h2", "Main page")
      |> refute_has("#incorrect-id", text: "Main page")
      |> refute_has("#incorrect-id", "Main page")
      |> refute_has("#title", text: "Not main page")
      |> refute_has("#title", "Not main page")
    end

    test "succeeds if no element is found with CSS selector and text (Live)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> refute_has("h1", text: "Not main page")
      |> refute_has("h1", "Not main page")
      |> refute_has("h2", text: "Main page")
      |> refute_has("h2", "Main page")
      |> refute_has("#incorrect-id", text: "Main page")
      |> refute_has("#incorrect-id", "Main page")
      |> refute_has("#title", text: "Not main page")
      |> refute_has("#title", "Not main page")
    end

    test "raises an error if one element is found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error1 =
        assert_raise AssertionError, fn ->
          refute_has(conn, "#title", text: "Main page")
        end

      assert_error_contains(error1, ["refute_has failed", "#title", "Main page", "unexpected matching text found"])

      error2 =
        assert_raise AssertionError, fn ->
          refute_has(conn, "#title", "Main page")
        end

      assert_error_contains(error2, ["refute_has failed", "#title", "Main page", "unexpected matching text found"])
    end

    test "raises an error if multiple elements are found", %{conn: conn} do
      conn = visit(conn, "/page/index")

      error1 =
        assert_raise AssertionError, fn ->
          refute_has(conn, ".multiple_links", text: "Multiple links")
        end

      assert_error_contains(error1, [
        "refute_has failed",
        ".multiple_links",
        "Multiple links",
        "unexpected matching text found"
      ])

      error2 =
        assert_raise AssertionError, fn ->
          refute_has(conn, ".multiple_links", "Multiple links")
        end

      assert_error_contains(error2, [
        "refute_has failed",
        ".multiple_links",
        "Multiple links",
        "unexpected matching text found"
      ])
    end

    test "accepts an `exact` option to match text exactly", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: "Main", exact: true)
      |> refute_has("h1", "Main", exact: true)
    end

    test "raises if `exact` text makes refutation false", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> refute_has("h1", text: "Main", exact: false)
        end

      assert_error_contains(error, ["refute_has failed", "h1", "Main", "unexpected matching text found"])
    end

    test "accepts non-binary text with Phoenix.HTML.Safe implementation", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("h1", text: :Main, exact: true)
      |> refute_has("h1", :Main, exact: true)
    end

    test "accepts an `at` option (without text) to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#single-list-item li", at: 2)
    end

    test "accepts an `at` option with text to refute on a specific element", %{conn: conn} do
      conn
      |> visit("/page/index")
      |> refute_has("#multiple-items li", at: 2, text: "Aragorn")
    end

    test "raises if it finds element at `at` position", %{conn: conn} do
      error =
        assert_raise AssertionError, fn ->
          conn
          |> visit("/page/index")
          |> refute_has("#multiple-items li", at: 2, text: "Legolas")
        end

      assert_error_contains(error, [
        "refute_has failed",
        "#multiple-items li:nth-child(2)",
        "Legolas",
        "unexpected matching text found"
      ])
    end

    test "can refute by value", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", value: "not-frodo")
    end

    test "can refute by non-binary value with Phoenix.HTML.Safe implementation", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", value: %Character{name: "not-frodo"})
    end

    test "can refute by value and implicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", label: "Halfling", value: "Frodo")
      |> refute_has("input", label: "Hobbit", value: "Sam")
    end

    test "can refute by value and explicit label", %{conn: conn} do
      conn
      |> visit("/page/by_value")
      |> refute_has("input", label: "Istari", value: "Gandalf")
      |> refute_has("input", label: "Wizard", value: "Saruman")
    end

    test "raises an error if value is found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      error =
        assert_raise AssertionError, fn ->
          refute_has(session, "input", value: "Frodo")
        end

      assert_error_contains(error, ["refute_has failed", "input", "Frodo"])
    end

    test "raises an error if label and value are found more/less than expected", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      refute_has(session, "input", label: "Kingdoms", value: "Gondor", count: 1)

      error =
        assert_raise AssertionError, fn ->
          refute_has(session, "input", label: "Kingdoms", value: "Gondor")
        end

      assert_error_contains(error, [~r/input/, "Gondor", "Kingdoms"])
    end

    test "raises an error if label and value are found", %{conn: conn} do
      session = visit(conn, "/page/by_value")

      error =
        assert_raise AssertionError, fn ->
          refute_has(session, "input", label: "Hobbit", value: "Frodo")
        end

      assert_error_contains(error, [~r/input/, "Frodo", "Hobbit"])
    end

    test "provides a clear error when trying to specify both text string arg and :text keyword arg", %{conn: conn} do
      session = visit(conn, "/page/index")

      error =
        assert_raise ArgumentError, fn ->
          refute_has(session, "h1", "Main page", text: "Other text", exact: true, count: 1)
        end

      assert_error_contains(error, ["Cannot specify", "text", ~s(refute_has(session, "h1", "Main page")])
    end
  end

  describe "assert_path" do
    test "asserts the session's current path" do
      session = %Live{current_path: "/page/index"}

      assert_path(session, "/page/index")
    end

    test "asserts query params are the same" do
      session = %Live{current_path: "/page/index?hello=world"}

      assert_path(session, "/page/index", query_params: %{"hello" => "world"})
    end

    test "asserts wildcard in expected path" do
      session = %Live{current_path: "/user/12345/profile"}

      assert_path(session, "/user/*/profile")
    end

    test "order of query params does not matter" do
      session = %Live{current_path: "/page/index?hello=world&foo=bar"}

      assert_path(session, "/page/index", query_params: %{"foo" => "bar", "hello" => "world"})
    end

    test "handles query params that have a list as a value" do
      session = %Live{current_path: "/page/index?users[]=frodo&users[]=sam"}

      assert_path(session, "/page/index", query_params: %{"users" => ["frodo", "sam"]})
    end

    test "handles query params that have a map as a value" do
      session = %Live{current_path: "/page/index?filter[name]=frodo&filter[height]=1.24m"}

      assert_path(session, "/page/index", query_params: %{"filter" => %{"name" => "frodo", "height" => "1.24m"}})
    end

    test "handles asserting empty query params" do
      session = %Live{current_path: "/page/index"}

      assert_path(session, "/page/index", query_params: %{})
    end

    test "raises helpful error if path doesn't match" do
      error =
        assert_raise AssertionError, fn ->
          session = %Live{current_path: "/page/index"}

          assert_path(session, "/page/not-index")
        end

      assert_error_contains(error, ["Expected current path", "/page/not-index", "/page/index", "to match"])
    end

    test "raises helpful error if path doesn't have query params" do
      error =
        assert_raise AssertionError, fn ->
          session = %Live{current_path: "/page/index"}

          assert_path(session, "/page/index", query_params: %{foo: "bar", details: true})
        end

      assert_error_contains(error, ["Expected query params", ~s(%{"details" => "true", "foo" => "bar"}), "got %{}"])
    end

    test "raises helpful error if query params don't match" do
      error =
        assert_raise AssertionError, fn ->
          session = %Live{current_path: "/page/index?hello=world&hi=bye"}

          assert_path(session, "/page/index", query_params: %{"goodbye" => "world", "hi" => "bye"})
        end

      assert_error_contains(error, [
        "Expected query params",
        ~s(%{"goodbye" => "world", "hi" => "bye"}),
        ~s(%{"hello" => "world", "hi" => "bye"})
      ])
    end

    test "raises helpful error if path doesn't have query params with lists" do
      session = %Live{current_path: "/page/index?users[]=frodo&users[]=sam"}

      error =
        assert_raise AssertionError, fn ->
          assert_path(session, "/page/index", query_params: %{"users" => ["sam"]})
        end

      assert_error_contains(error, [
        "Expected query params",
        ~s(%{"users" => ["sam"]}),
        ~s(%{"users" => ["frodo", "sam"]})
      ])
    end
  end

  describe "refute_path" do
    test "refute the given path is the current path" do
      session = %Live{current_path: "/page/index"}

      refute_path(session, "/page/page_2")
    end

    test "refutes query params are the same" do
      session = %Live{current_path: "/page/index?hello=world"}

      refute_path(session, "/page/index", query_params: %{"hello" => "not-world"})
    end

    test "raises helpful error if path matches" do
      error =
        assert_raise AssertionError, fn ->
          session = %Live{current_path: "/page/index"}

          refute_path(session, "/page/index")
        end

      assert_error_contains(error, ["Expected current path", "/page/index", "NOT match"])
    end

    test "raises helpful error if query params MATCH" do
      error =
        assert_raise AssertionError, fn ->
          session = %Live{current_path: "/page/index?hello=world&hi=bye"}

          refute_path(session, "/page/index", query_params: %{"hello" => "world", "hi" => "bye"})
        end

      assert_error_contains(error, ["Expected current path", "/page/index?hello=world&hi=bye", "NOT match", "/page/index"])
    end
  end
end
