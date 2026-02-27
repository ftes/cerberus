defmodule Cerberus.Fixtures.SandboxMessage do
  @moduledoc false
  use Ecto.Schema

  schema "sandbox_messages" do
    field(:body, :string)
    timestamps(type: :utc_datetime_usec)
  end
end
