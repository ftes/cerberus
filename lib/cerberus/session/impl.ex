defimpl Cerberus.Session, for: Cerberus.Driver.Static do
  def scope(%{scope: scope}), do: scope
  def with_scope(session, scope), do: %{session | scope: scope}
end

defimpl Cerberus.Session, for: Cerberus.Driver.Live do
  def scope(%{scope: scope}), do: scope
  def with_scope(session, scope), do: %{session | scope: scope}
end

defimpl Cerberus.Session, for: Cerberus.Driver.Browser do
  def scope(%{scope: scope}), do: scope
  def with_scope(session, scope), do: %{session | scope: scope}
end
