defmodule Cerberus.TestSupport.BrowserSessions do
  @moduledoc false

  import Cerberus
  import Cerberus.Browser

  @spec session!(keyword()) :: Cerberus.session_handle()
  def session!(opts \\ []) when is_list(opts) do
    limit_concurrent_tests()
    session(:browser, opts)
  end

  @spec setup_browser_session(keyword()) :: {:ok, [browser_session: Cerberus.session_handle()]}
  def setup_browser_session(opts \\ []) when is_list(opts) do
    {:ok, browser_session: session!(opts)}
  end
end
