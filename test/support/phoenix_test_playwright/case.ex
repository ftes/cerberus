defmodule Cerberus.TestSupport.PhoenixTestPlaywright.Case do
  @moduledoc false

  use ExUnit.CaseTemplate

  using opts do
    opts = Keyword.put(opts, :async, false)

    quote do
      use ExUnit.Case, unquote(opts)

      import Cerberus.TestSupport.PhoenixTestPlaywright.Legacy
      import Cerberus.TestSupport.PhoenixTestPlaywright.TestHelpers
    end
  end

  setup do
    %{conn: Cerberus.session(:browser)}
  end
end
