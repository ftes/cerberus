ExUnit.start()

port =
  System.get_env("PORT", "4101")
  |> String.to_integer()

Application.put_env(
  :cerberus,
  Cerberus.Fixtures.Endpoint,
  server: true,
  http: [ip: {127, 0, 0, 1}, port: port],
  url: [host: "127.0.0.1", port: port],
  secret_key_base: String.duplicate("cerberus-secret-key-base-", 5),
  live_view: [signing_salt: "cerberus-live-view-signing-salt"],
  pubsub_server: Cerberus.Fixtures.PubSub
)

{:ok, _} =
  Supervisor.start_link(
    [
      {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
      Cerberus.Driver.Browser.Supervisor
    ],
    strategy: :one_for_one
  )

{:ok, _} = Cerberus.Fixtures.Endpoint.start_link()

Application.put_env(:cerberus, :endpoint, Cerberus.Fixtures.Endpoint)
Application.put_env(:cerberus, :base_url, Cerberus.Fixtures.Endpoint.url())

chrome_binary =
  [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
  ]
  |> Enum.find(&File.exists?/1)

version_from_binary = fn binary ->
  cmd_result =
    try do
      {:ok, System.cmd(binary, ["--version"], stderr_to_stdout: true)}
    rescue
      ErlangError -> :error
    end

  with true <- is_binary(binary),
       true <- File.exists?(binary),
       {:ok, {output, 0}} <- cmd_result,
       [version] <- Regex.run(~r/\d+\.\d+\.\d+\.\d+/, output) do
    version
  else
    _ -> nil
  end
end

major_from_version = fn
  nil -> nil
  version -> version |> String.split(".") |> List.first()
end

chrome_major =
  chrome_binary
  |> version_from_binary.()
  |> major_from_version.()

chromedriver_candidates =
  Path.wildcard("tmp/browser-tools/chromedriver-*/chromedriver-*/chromedriver")
  |> Enum.concat(
    case System.find_executable("chromedriver") do
      nil -> []
      binary -> [binary]
    end
  )
  |> Enum.uniq()

chromedriver_binary =
  Enum.find(chromedriver_candidates, fn binary ->
    binary
    |> version_from_binary.()
    |> major_from_version.() == chrome_major
  end) ||
    List.first(chromedriver_candidates)

browser_opts =
  []
  |> then(fn opts ->
    if is_binary(chromedriver_binary),
      do: Keyword.put(opts, :chromedriver_binary, chromedriver_binary),
      else: opts
  end)
  |> then(fn opts ->
    if is_binary(chrome_binary), do: Keyword.put(opts, :chrome_binary, chrome_binary), else: opts
  end)

Application.put_env(:cerberus, :browser, browser_opts)
