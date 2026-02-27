defmodule Cerberus.CoreFormButtonOwnershipTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:static, :browser]

  test "non-submit controls do not clear active form values before submit", context do
    Enum.each(context.drivers, fn driver ->
      session =
        driver
        |> session()
        |> visit("/owner-form")
        |> fill_in([text: "Name"], "Aragorn")

      driver_module = Cerberus.driver_module!(driver)
      reset_locator = Cerberus.Locator.normalize(text: "Reset")
      save_locator = Cerberus.Locator.normalize(text: "Save Owner Form")

      assert {:error, session_after_reset, _observed, _reason} =
               driver_module.submit(session, reset_locator, [])

      assert {:ok, submitted_session, _observed} =
               driver_module.submit(session_after_reset, save_locator, [])

      submitted_session
      |> assert_has([text: "name: Aragorn"], exact: true)
      |> assert_has([text: "form-button: save-owner-form"], exact: true)
    end)
  end

  test "owner-form submit includes button payload across drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/owner-form")
        |> fill_in([text: "Name"], "Aragorn")
        |> submit(text: "Save Owner Form")
        |> assert_has([text: "name: Aragorn"], exact: true)
        |> assert_has([text: "form-button: save-owner-form"], exact: true)
      end
    )
  end

  test "submit clears active form values for subsequent submits", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/owner-form")
        |> fill_in([text: "Name"], "Aragorn")
        |> submit(text: "Save Owner Form")
        |> visit("/owner-form")
        |> submit(text: "Save Owner Form")
        |> assert_has([text: "name: "], exact: true)
        |> assert_has([text: "form-button: save-owner-form"], exact: true)
      end
    )
  end

  test "button formaction submit follows redirect and preserves button payload", context do
    Harness.run!(
      context,
      fn session ->
        session =
          session
          |> visit("/owner-form")
          |> fill_in([text: "Name"], "Aragorn")
          |> submit(text: "Save Owner Form Redirect")
          |> assert_has([text: "name: Aragorn"], exact: true)
          |> assert_has([text: "form-button: save-owner-form-redirect"], exact: true)

        assert String.starts_with?(session.current_path || "", "/owner-form/result")
        session
      end
    )
  end
end
