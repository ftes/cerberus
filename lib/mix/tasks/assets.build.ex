defmodule Mix.Tasks.Assets.Build do
  @shortdoc "Builds fixture browser assets"
  @moduledoc """
  Copies fixture browser assets into `priv/static` for test endpoint serving.

  This project intentionally avoids a bundler for fixture assets; the only
  required step is syncing `assets/js/app.js` into `priv/static/assets/app.js`.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    source = Path.expand("assets/js/app.js")
    target = Path.expand("priv/static/assets/app.js")

    File.mkdir_p!(Path.dirname(target))
    File.cp!(source, target)

    IO.puts("Copied assets/js/app.js -> priv/static/assets/app.js")
  end
end
