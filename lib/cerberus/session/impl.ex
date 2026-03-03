defimpl Cerberus.Session, for: Cerberus.Driver.Static do
  def current_path(%{current_path: current_path}), do: current_path
  def scope(%{scope: scope}), do: scope
  def with_scope(session, scope), do: %{session | scope: scope}
  def last_result(%{last_result: last_result}), do: last_result
end

defimpl Cerberus.Session, for: Cerberus.Driver.Live do
  def current_path(%{current_path: current_path}), do: current_path
  def scope(%{scope: scope}), do: scope
  def with_scope(session, scope), do: %{session | scope: scope}
  def last_result(%{last_result: last_result}), do: last_result
end

defimpl Cerberus.Session, for: Cerberus.Driver.Browser do
  def current_path(%{current_path: current_path}), do: current_path
  def scope(%{scope: scope}), do: scope
  def with_scope(session, scope), do: %{session | scope: scope}
  def last_result(%{last_result: last_result}), do: last_result
end
