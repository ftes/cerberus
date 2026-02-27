defmodule Cerberus.Fixtures.SandboxMessages do
  @moduledoc false

  import Ecto.Query

  alias Cerberus.Fixtures.Repo
  alias Cerberus.Fixtures.SandboxMessage

  @spec insert!(String.t()) :: SandboxMessage.t()
  def insert!(body) when is_binary(body) do
    Repo.insert!(%SandboxMessage{body: body})
  end

  @spec list_bodies() :: [String.t()]
  def list_bodies do
    Repo.all(
      from(message in SandboxMessage,
        order_by: [asc: message.id],
        select: message.body
      )
    )
  end
end
