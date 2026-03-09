defmodule Cerberus.Driver.Browser.Types do
  @moduledoc false

  @type browser_name :: :chrome | :firefox
  @type payload_key :: String.t() | atom()
  @type payload :: %{optional(payload_key()) => term()}
  @type bidi_params :: %{optional(String.t()) => term()}
  @type bidi_result :: %{optional(String.t()) => term()}
  @type bidi_error_details :: %{optional(String.t()) => term()}
  @type bidi_response :: {:ok, bidi_result()} | {:error, String.t(), bidi_error_details()}
  @type readiness_payload :: %{optional(String.t()) => term()}

  @type webdriver_capabilities :: %{optional(String.t()) => term()}
  @type webdriver_session_payload :: %{optional(String.t()) => term()}

  @type cookie :: %{
          name: String.t() | nil,
          value: term(),
          domain: String.t() | nil,
          path: String.t() | nil,
          http_only: boolean(),
          secure: boolean(),
          same_site: String.t() | nil,
          session: boolean()
        }
end
