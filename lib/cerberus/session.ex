defprotocol Cerberus.Session do
  @moduledoc "Runtime session access protocol used by Cerberus drivers."

  @type observed :: %{optional(String.t() | atom()) => term()}
  @type scope_value :: String.t() | observed() | nil
  @type transition :: observed()
  @type operation ::
          :visit
          | :click
          | :fill_in
          | :select
          | :choose
          | :check
          | :uncheck
          | :upload
          | :submit
          | :assert_has
          | :refute_has
          | :assert_path
          | :refute_path
          | :unwrap
  @type result :: %{
          op: operation(),
          observed: observed() | nil,
          transition: transition() | nil
        }
  @type t :: struct()

  @spec scope(t()) :: scope_value()
  def scope(session)

  @spec with_scope(t(), scope_value()) :: t()
  def with_scope(session, scope)
end
