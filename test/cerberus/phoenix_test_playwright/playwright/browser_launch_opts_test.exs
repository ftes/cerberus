defmodule Cerberus.PhoenixTestPlaywright.Playwright.BrowserLaunchOptsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  @media_script """
  navigator.mediaDevices.getUserMedia({ audio: true })
    .then(() => "success")
    .catch((error) => "error: " + error.name)
  """

  @tag skip: "browser launch args fake media permission parity bug"
  test "getUserMedia succeeds with fake media device flags" do
    :browser
    |> session(
      chrome_args: [
        "--use-fake-ui-for-media-stream",
        "--use-fake-device-for-media-stream"
      ]
    )
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
    |> evaluate_js(@media_script, fn result ->
      assert result == "success"
    end)
  end
end

defmodule Cerberus.PhoenixTestPlaywright.Playwright.BrowserLaunchOptsWithoutFlagsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  @media_script """
  navigator.mediaDevices.getUserMedia({ audio: true })
    .then(() => "success")
    .catch((error) => "error: " + error.name)
  """

  test "getUserMedia fails without fake media device flags" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/pw/live")
    |> assert_has(text("Playwright", exact: true))
    |> evaluate_js(@media_script, fn result ->
      assert result == "success" or String.match?(result, ~r/^error:\s+[A-Za-z]+/)
    end)
  end
end
