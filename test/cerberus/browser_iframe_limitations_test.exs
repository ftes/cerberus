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
end
