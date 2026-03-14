defmodule Cerberus.TestSupport.LiveFormActionBenchmark do
  @moduledoc false

  import Cerberus

  @path "/live/controls"

  @spec run_flow(Cerberus.Session.t(), keyword()) :: Cerberus.Session.t()
  def run_flow(session, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)

    session
    |> visit(@path)
    |> assert_has(role(:heading, name: "Live Controls", exact: true), timeout: timeout_ms)
    |> select(~l"Race"l, ~l"Elf"e)
    |> assert_has(text("race: elf", exact: true), timeout: timeout_ms)
    |> fill_in(~l"Age"l, "41")
    |> assert_has(text("age: 41", exact: true), timeout: timeout_ms)
    |> choose(~l"Phone Choice"l)
    |> assert_has(text("contact: phone", exact: true), timeout: timeout_ms)
    |> select(~l"Race"l, ~l"Dwarf"e)
    |> assert_has(text("race: dwarf", exact: true), timeout: timeout_ms)
    |> fill_in(~l"Age"l, "42")
    |> assert_has(text("age: 42", exact: true), timeout: timeout_ms)
    |> choose(~l"Email Choice"l)
    |> assert_has(text("contact: email", exact: true), timeout: timeout_ms)
    |> select(~l"Race"l, ~l"Elf"e)
    |> assert_has(text("race: elf", exact: true), timeout: timeout_ms)
    |> fill_in(~l"Age"l, "43")
    |> assert_has(text("age: 43", exact: true), timeout: timeout_ms)
    |> choose(~l"Phone Choice"l)
    |> assert_has(text("contact: phone", exact: true), timeout: timeout_ms)
    |> select(~l"Race"l, ~l"Dwarf"e)
    |> assert_has(text("race: dwarf", exact: true), timeout: timeout_ms)
    |> fill_in(~l"Age"l, "44")
    |> assert_has(text("age: 44", exact: true), timeout: timeout_ms)
    |> choose(~l"Email Choice"l)
    |> assert_has(text("contact: email", exact: true), timeout: timeout_ms)
  end
end
