defmodule Cerberus.InvalidLocatorError do
  @moduledoc "Raised when a locator value cannot be normalized."

  defexception [:message, :locator]

  @impl true
  def exception(opts) do
    locator = Keyword.get(opts, :locator)

    message =
      Keyword.get(
        opts,
        :message,
        "invalid locator #{inspect(locator)}; expected text string, regex, or [text: ...]"
      )

    %__MODULE__{message: message, locator: locator}
  end
end
