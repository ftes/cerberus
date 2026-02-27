alias Cerberus.Fixtures.Endpoint

ExUnit.start()

{:ok, _} =
  Supervisor.start_link(
    [
      {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
      Cerberus.Driver.Browser.Supervisor
    ],
    strategy: :one_for_one
  )

{:ok, _} = Endpoint.start_link()
Application.put_env(:cerberus, :base_url, Endpoint.url())
