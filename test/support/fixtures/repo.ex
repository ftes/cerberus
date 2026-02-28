defmodule Cerberus.Fixtures.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :cerberus,
    adapter: Ecto.Adapters.Postgres
end
