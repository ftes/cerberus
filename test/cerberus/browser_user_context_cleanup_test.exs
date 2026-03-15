defmodule Cerberus.BrowserUserContextCleanupTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Browser, as: BrowserHelpers
  alias Cerberus.Driver.Browser.BiDi

  test "browser user contexts are removed after the owning process exits" do
    parent = self()
    BrowserHelpers.limit_concurrent_tests()

    pid =
      spawn(fn ->
        session = session(:browser)
        user_context_id = :sys.get_state(session.user_context_pid).user_context_id
        send(parent, {:user_context_id, user_context_id})
      end)

    user_context_id =
      receive do
        {:user_context_id, value} -> value
      after
        5_000 -> flunk("expected spawned browser session to report a user context id")
      end

    on_exit(fn ->
      _ = BiDi.command("browser.removeUserContext", %{"userContext" => user_context_id}, [])
    end)

    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 5_000

    assert_eventually_removed(user_context_id)
  end

  defp assert_eventually_removed(user_context_id, attempts \\ 20)

  defp assert_eventually_removed(user_context_id, attempts) when attempts > 0 do
    ids = user_context_ids()

    if user_context_id in ids do
      Process.sleep(50)
      assert_eventually_removed(user_context_id, attempts - 1)
    else
      :ok
    end
  end

  defp assert_eventually_removed(user_context_id, 0) do
    flunk("expected browser user context #{inspect(user_context_id)} to be removed after owner exit")
  end

  defp user_context_ids do
    case BiDi.command("browser.getUserContexts", %{}, []) do
      {:ok, %{"userContexts" => contexts}} when is_list(contexts) ->
        contexts
        |> Enum.map(& &1["userContext"])
        |> Enum.sort()

      other ->
        flunk("expected browser.getUserContexts to succeed, got: #{inspect(other)}")
    end
  end
end
