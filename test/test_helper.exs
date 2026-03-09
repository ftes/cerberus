alias Cerberus.Fixtures.AuthStore
alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

ExUnit.start(max_cases: 28)

{:ok, _} =
  Supervisor.start_link(
    [
      Repo,
      AuthStore,
      {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
      Cerberus.Driver.Browser.Supervisor
    ],
    strategy: :one_for_one,
    name: Cerberus.TestSupportSupervisor
  )

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
AuthStore.reset!()

{:ok, _} = Endpoint.start_link()

ExUnit.after_suite(fn _results ->
  if Cerberus.Profiling.enabled?() do
    Cerberus.Profiling.dump_summary()
  end

  case Process.whereis(Cerberus.TestSupportSupervisor) do
    pid when is_pid(pid) -> _ = Supervisor.stop(pid, :normal, 15_000)
    _ -> :ok
  end
end)
