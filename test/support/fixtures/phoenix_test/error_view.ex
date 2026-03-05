defmodule Cerberus.Fixtures.PhoenixTest.ErrorView do
  use Phoenix.Component

  def render(_template, assigns) do
    reason_message =
      case Map.get(assigns, :reason) do
        reason when is_exception(reason) -> Exception.message(reason)
        reason -> inspect(reason)
      end

    assigns = assign(assigns, :reason_message, reason_message)

    ~H"""
    <h2>{@status}</h2>
    <p>{@reason_message}</p>
    """
  end
end
