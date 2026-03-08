defmodule Cerberus.BrowserProtocolRoundtripBenchmarkTest do
  use ExUnit.Case, async: false

  alias Cerberus.TestSupport.BrowserProtocolRoundtripBenchmark

  @moduletag :slow

  test "raw Chrome BiDi and CDP roundtrip benchmark" do
    result = BrowserProtocolRoundtripBenchmark.run(commands: 1_000)

    IO.puts("""

    Raw Chrome protocol benchmark
      commands: #{result.commands}
      BiDi total: #{result.bidi.total_ms}ms (avg #{Float.round(result.bidi.avg_ms, 2)}ms)
      CDP total: #{result.cdp.total_ms}ms (avg #{Float.round(result.cdp.avg_ms, 2)}ms)
    """)

    assert result.bidi.commands == 1_000
    assert result.cdp.commands == 1_000
  end
end
