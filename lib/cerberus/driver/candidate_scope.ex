defmodule Cerberus.Driver.CandidateScope do
  @moduledoc false

  alias Cerberus.Locator

  @type scope_value :: String.t() | nil

  @spec click_scope(keyword(), scope_value()) :: scope_value()
  def click_scope(match_opts, current_scope) when is_list(match_opts) do
    match_opts
    |> Keyword.get(:locator)
    |> locator_scope_selector()
    |> merge_scope(current_scope)
  end

  @spec css_scoped_text_candidates?(keyword()) :: boolean()
  def css_scoped_text_candidates?(match_opts) when is_list(match_opts) do
    match_by = Keyword.get(match_opts, :match_by, :text)

    if match_by == :text do
      case Keyword.get(match_opts, :locator) do
        %Locator{} = locator -> is_binary(locator_scope_selector(locator))
        _ -> false
      end
    else
      false
    end
  end

  @spec locator_scope_selector(term()) :: String.t() | nil
  def locator_scope_selector(%Locator{kind: :css, value: value}) when is_binary(value), do: value

  def locator_scope_selector(%Locator{kind: :and, value: members}) when is_list(members) do
    Enum.find_value(members, &locator_scope_selector/1)
  end

  def locator_scope_selector(%Locator{}), do: nil
  def locator_scope_selector(_), do: nil

  @spec merge_scope(scope_value(), scope_value()) :: scope_value()
  def merge_scope(nil, current_scope), do: current_scope
  def merge_scope(locator_scope, nil), do: locator_scope
  def merge_scope(locator_scope, current_scope), do: "#{current_scope} #{locator_scope}"
end
