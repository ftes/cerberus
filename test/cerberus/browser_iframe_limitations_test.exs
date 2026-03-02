defmodule Cerberus.BrowserIframeLimitationsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  test "cross-origin iframe DOM access is blocked by same-origin policy" do
    session =
      :browser
      |> session()
      |> visit("/browser/iframe/cross-origin")

    result =
      evaluate_js(
        session,
        """
        (() => {
          const iframe = document.getElementById("cross-origin-frame");

          try {
            return {
              ok: true,
              text: iframe.contentWindow.document.body.innerText
            };
          } catch (error) {
            return {
              ok: false,
              reason: "cross_origin_blocked",
              name: error && error.name ? error.name : null,
              message: String(error && error.message ? error.message : "")
            };
          }
        })()
        """
      )

    assert result["ok"] == false
    assert result["reason"] == "cross_origin_blocked"
    assert is_binary(result["message"])
    assert result["message"] != ""
    assert result["name"] in [nil, "DOMException", "SecurityError"]
  end

  test "unguarded cross-origin iframe DOM access raises browser evaluate error" do
    session =
      :browser
      |> session()
      |> visit("/browser/iframe/cross-origin")

    error =
      assert_raise ArgumentError, fn ->
        evaluate_js(
          session,
          """
          (() => {
            const iframe = document.getElementById("cross-origin-frame");
            return iframe.contentWindow.document.body.innerText;
          })()
          """
        )
      end

    assert error.message =~ "browser evaluate_js failed:"
  end

  test "within locator scopes browser operations into same-origin iframe document" do
    :browser
    |> session()
    |> visit("/browser/iframe/same-origin")
    |> within(css("#same-origin-frame"), fn frame_scope ->
      frame_scope
      |> assert_has(text("Same-origin iframe body marker", exact: true))
      |> click(button("Frame Increment", exact: true))
      |> assert_has(text("Frame Count: 1", exact: true))
    end)
    |> assert_has(text("Outside iframe marker", exact: true))
  end

  test "within locator rejects cross-origin iframe root switching" do
    error =
      assert_raise ExUnit.AssertionError, fn ->
        :browser
        |> session()
        |> visit("/browser/iframe/cross-origin")
        |> within(css("#cross-origin-frame"), fn frame_scope ->
          frame_scope
        end)
      end

    assert error.message =~ "within/3 only supports same-origin iframes in browser mode"
  end
end
