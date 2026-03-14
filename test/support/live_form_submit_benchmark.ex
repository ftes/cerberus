defmodule Cerberus.TestSupport.LiveFormSubmitBenchmark do
  @moduledoc false

  import Cerberus

  @path "/live/form-sync"

  @spec run_flow(Cerberus.Session.t(), keyword()) :: Cerberus.Session.t()
  def run_flow(session, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)

    session
    |> visit(@path)
    |> assert_has(role(:button, name: "Save No Change", exact: true), timeout: timeout_ms)
    |> run_submit_cycle("Aragorn", timeout_ms)
    |> run_submit_cycle("Legolas", timeout_ms)
    |> run_submit_cycle("Gimli", timeout_ms)
    |> run_submit_cycle("Frodo", timeout_ms)
  end

  defp run_submit_cycle(session, value, timeout_ms) do
    session
    |> fill_in(~l"Nickname (submit only)"l, value)
    |> submit(role(:button, name: "Save No Change", exact: true))
    |> assert_has(text("no-change submitted: #{value}", exact: true), timeout: timeout_ms)
  end
end
