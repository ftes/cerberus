defmodule Cerberus.CoreBrowserMultiSessionConformanceTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser.UserContextProcess

  @moduletag :conformance
  @moduletag browser: true

  test "browser user context supports deterministic open/switch/close tab workflows" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> assert_has(text("Articles"), exact: true)

    user_context_pid = session.user_context_pid
    primary_tab = UserContextProcess.active_tab(user_context_pid)
    assert is_binary(primary_tab)
    assert UserContextProcess.tabs(user_context_pid) == [primary_tab]

    assert {:ok, secondary_tab} = UserContextProcess.open_tab(user_context_pid)
    assert secondary_tab != primary_tab
    assert UserContextProcess.active_tab(user_context_pid) == secondary_tab
    assert Enum.sort(UserContextProcess.tabs(user_context_pid)) == Enum.sort([primary_tab, secondary_tab])

    session =
      session
      |> visit("/live/counter")
      |> click(button("Increment"))
      |> assert_has(text("Count: 1"), exact: true)

    assert :ok = UserContextProcess.switch_tab(user_context_pid, primary_tab)

    session =
      session
      |> assert_has(text("Articles"), exact: true)
      |> assert_path("/articles")

    assert :ok = UserContextProcess.close_tab(user_context_pid, secondary_tab)
    assert UserContextProcess.tabs(user_context_pid) == [primary_tab]
    assert UserContextProcess.active_tab(user_context_pid) == primary_tab
    assert {:error, "cannot close last tab", _details} = UserContextProcess.close_tab(user_context_pid, primary_tab)
    assert session.current_path == "/articles"
  end

  test "parallel browser sessions remain isolated under concurrent actions" do
    session_a =
      :browser
      |> session()
      |> visit("/live/counter")
      |> assert_has(text("Count: 0"), exact: true)

    session_b =
      :browser
      |> session()
      |> visit("/live/counter")
      |> assert_has(text("Count: 0"), exact: true)

    user_context_a = :sys.get_state(session_a.user_context_pid).user_context_id
    user_context_b = :sys.get_state(session_b.user_context_pid).user_context_id
    refute user_context_a == user_context_b

    barrier = make_ref()

    task_fun = fn initial_session ->
      receive do
        {:go, ^barrier} ->
          initial_session
          |> click(button("Increment"))
          |> assert_has(text("Count: 1"), exact: true)
      end
    end

    task_a = Task.async(fn -> task_fun.(session_a) end)
    task_b = Task.async(fn -> task_fun.(session_b) end)

    send(task_a.pid, {:go, barrier})
    send(task_b.pid, {:go, barrier})

    updated_a = Task.await(task_a, 10_000)
    updated_b = Task.await(task_b, 10_000)

    assert_has(updated_a, text("Count: 1"), exact: true)
    assert_has(updated_b, text("Count: 1"), exact: true)
  end
end
