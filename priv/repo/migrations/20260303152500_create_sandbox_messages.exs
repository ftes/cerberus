defmodule Cerberus.Fixtures.Repo.Migrations.CreateSandboxMessages do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:sandbox_messages) do
      add :body, :text, null: false
      timestamps(type: :utc_datetime_usec)
    end
  end
end
