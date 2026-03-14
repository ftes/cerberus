alias Cerberus.TestSupport.MatchRoundContract

Mix.env(:test)

Code.require_file("../test/support/match_round_contract.ex", __DIR__)

input_dir = Path.join(System.tmp_dir!(), "cerberus-match-round")
File.mkdir_p!(input_dir)

cases = MatchRoundContract.cases()
node = System.find_executable("node") || raise "node executable not found"
runner = Path.join(__DIR__, "browser_match_round_runner.js")

Enum.each(cases, fn contract_case ->
  html_result = MatchRoundContract.html_round(contract_case)
  input_path = Path.join(input_dir, "#{contract_case.id}.json")
  File.write!(input_path, JSON.encode!(MatchRoundContract.browser_input(contract_case)))

  {raw_browser, 0} = System.cmd(node, [runner, input_path], cd: File.cwd!())

  browser_result =
    raw_browser
    |> JSON.decode!()
    |> MatchRoundContract.normalize_round_result(Map.take(contract_case, [:kind, :op]))

  if html_result != browser_result do
    raise """
    round contract mismatch for #{contract_case.id}
    html:    #{inspect(html_result, pretty: true)}
    browser: #{inspect(browser_result, pretty: true)}
    """
  end

  IO.puts("#{contract_case.id}: ok")
end)
