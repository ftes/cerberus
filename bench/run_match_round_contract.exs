alias Cerberus.TestSupport.MatchRoundContract

Mix.env(:test)

Code.require_file("../test/support/match_round_contract.ex", __DIR__)

cases = MatchRoundContract.cases()

Enum.each(cases, fn contract_case ->
  html_result = MatchRoundContract.html_round(contract_case)
  browser_result = MatchRoundContract.browser_round(contract_case)

  if html_result != browser_result do
    raise """
    round contract mismatch for #{contract_case.id}
    html:    #{inspect(html_result, pretty: true)}
    browser: #{inspect(browser_result, pretty: true)}
    """
  end

  IO.puts("#{contract_case.id}: ok")
end)
