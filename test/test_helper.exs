alias Cerberus.Fixtures.Endpoint
alias Cerberus.Fixtures.Repo

ExUnit.start()

if db_path = Repo.config()[:database] do
  File.mkdir_p!(Path.dirname(db_path))
  File.rm(db_path)
end

{:ok, _} =
  Supervisor.start_link(
    [
      Repo,
      {Phoenix.PubSub, name: Cerberus.Fixtures.PubSub},
      Cerberus.Driver.Browser.Supervisor
    ],
    strategy: :one_for_one
  )

Ecto.Adapters.SQL.query!(
  Repo,
  """
  CREATE TABLE IF NOT EXISTS sandbox_messages (
    id INTEGER PRIMARY KEY,
    body TEXT NOT NULL,
    inserted_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  """,
  []
)

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)

{:ok, _} = Endpoint.start_link()
Application.put_env(:cerberus, :base_url, Endpoint.url())
