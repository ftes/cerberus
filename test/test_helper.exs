ExUnit.start()

{:ok, _} =
  Supervisor.start_link(
    [
      {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
      Cerberus.Driver.Browser.Supervisor
    ],
    strategy: :one_for_one
  )

{:ok, _} = Cerberus.Fixtures.Endpoint.start_link()
