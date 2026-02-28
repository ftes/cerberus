defmodule Cerberus.CoreFormButtonOwnershipTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Phoenix.ConnTest, only: [build_conn: 0]

  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:static, :browser]

  test "non-submit controls do not clear active form values before submit", context do
    Harness.run!(
      context,
      fn session ->
        driver_module = Cerberus.driver_module!(session)
        reset_locator = Cerberus.Locator.normalize(text: "Reset")
        save_locator = Cerberus.Locator.normalize(text: "Save Owner Form")

        session =
          session
          |> visit("/owner-form")
          |> fill_in("Name", "Aragorn")

        assert {:error, session_after_reset, _observed, _reason} =
                 driver_module.submit(session, reset_locator, [])

        assert {:ok, submitted_session, _observed} =
                 driver_module.submit(session_after_reset, save_locator, [])

        submitted_session
        |> assert_has(text: "name: Aragorn", exact: true)
        |> assert_has(text: "form-button: save-owner-form", exact: true)
      end
    )
  end

  test "owner-form submit includes button payload across drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/owner-form")
        |> fill_in("Name", "Aragorn")
        |> submit(text: "Save Owner Form")
        |> assert_has(text: "name: Aragorn", exact: true)
        |> assert_has(text: "form-button: save-owner-form", exact: true)
      end
    )
  end

  test "submit clears active form values for subsequent submits", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/owner-form")
        |> fill_in("Name", "Aragorn")
        |> submit(text: "Save Owner Form")
        |> visit("/owner-form")
        |> submit(text: "Save Owner Form")
        |> assert_has(text: "name: ", exact: true)
        |> assert_has(text: "form-button: save-owner-form", exact: true)
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
          |> fill_in("Name", "Aragorn")
          |> submit(text: "Save Owner Form Redirect")
          |> assert_has(text: "name: Aragorn", exact: true)
          |> assert_has(text: "form-button: save-owner-form-redirect", exact: true)

        assert String.starts_with?(session.current_path || "", "/owner-form/result")
        session
      end
    )
  end

  @tag drivers: [:static, :live]
  test "active form state persists after non-submit and clears after submit", context do
    seed_conn = Plug.Conn.put_req_header(build_conn(), "x-flow-token", "active-form-state")

    Harness.run!(
      context,
      fn session ->
        session =
          session
          |> Map.put(:conn, seed_conn)
          |> visit("/owner-form")
          |> fill_in("Name", "Aragorn")

        assert %{active_form: active_before} = session.form_data
        assert is_binary(active_before)

        driver_module = Cerberus.driver_module!(session)
        reset_locator = Cerberus.Locator.normalize(text: "Reset")
        save_locator = Cerberus.Locator.normalize(text: "Save Owner Form")

        assert {:error, after_reset, _observed, _reason} =
                 driver_module.submit(session, reset_locator, [])

        assert %{active_form: active_after_reset} = after_reset.form_data
        assert active_after_reset == active_before

        assert {:ok, after_submit, _observed} =
                 driver_module.submit(after_reset, save_locator, [])

        assert %{active_form: nil} = after_submit.form_data
        after_submit
      end
    )
  end

  @tag drivers: [:static, :live]
  test "button-driven redirect submit preserves request headers", context do
    seed_conn = Plug.Conn.put_req_header(build_conn(), "x-flow-token", "flow-123")

    Harness.run!(
      context,
      fn session ->
        session =
          session
          |> Map.put(:conn, seed_conn)
          |> visit("/owner-form")
          |> fill_in("Name", "Aragorn")
          |> submit(text: "Save Owner Form Redirect")
          |> assert_has(text: "name: Aragorn", exact: true)
          |> assert_has(text: "form-button: save-owner-form-redirect", exact: true)
          |> assert_has(text: "x-flow-token: flow-123", exact: true)

        assert String.starts_with?(session.current_path || "", "/owner-form/result")
        session
      end
    )
  end
end
