defmodule Cerberus.Driver.Browser.MatchRoundPayload do
  @moduledoc false

  alias Cerberus.Driver.Browser.Config
  alias Cerberus.Locator

  @type assertion_payload :: %{
          required(:locator) => map(),
          required(:mode) => String.t(),
          required(:visibility) => String.t(),
          optional(:count) => non_neg_integer() | nil,
          optional(:min) => non_neg_integer() | nil,
          optional(:max) => non_neg_integer() | nil,
          optional(:between) => {non_neg_integer(), non_neg_integer()} | nil
        }

  @type action_payload :: %{
          required(:op) => String.t(),
          required(:expected) => map(),
          required(:matchBy) => String.t(),
          required(:exact) => boolean(),
          required(:normalizeWs) => boolean(),
          optional(:locator) => map() | nil,
          optional(:kind) => String.t() | nil,
          optional(:count) => non_neg_integer() | nil,
          optional(:min) => non_neg_integer() | nil,
          optional(:max) => non_neg_integer() | nil,
          optional(:between) => {non_neg_integer(), non_neg_integer()} | nil,
          optional(:first) => boolean(),
          optional(:last) => boolean(),
          optional(:nth) => pos_integer() | nil,
          optional(:index) => non_neg_integer() | nil,
          optional(:checked) => boolean() | nil,
          optional(:disabled) => boolean() | nil,
          optional(:selected) => boolean() | nil,
          optional(:readonly) => boolean() | nil,
          optional(:visible) => boolean() | nil
        }

  @spec assertion(Locator.t(), keyword()) :: assertion_payload()
  def assertion(%Locator{} = locator, opts) when is_list(opts) do
    %{
      locator: locator(locator),
      mode: Atom.to_string(Keyword.get(opts, :mode, :assert)),
      visibility: visibility_payload(locator, opts),
      count: Keyword.get(opts, :count),
      min: Keyword.get(opts, :min),
      max: Keyword.get(opts, :max),
      between: Keyword.get(opts, :between)
    }
  end

  @spec action(atom(), String.t() | Regex.t(), keyword()) :: action_payload()
  def action(op, expected, opts)
      when op in [:click, :fill_in, :submit, :select, :choose, :check, :uncheck, :upload] and is_list(opts) do
    %{
      op: Atom.to_string(op),
      kind: action_kind_payload(op, opts),
      locator: nested_locator_payload(Keyword.get(opts, :locator)),
      expected: Config.text_expectation_payload(expected),
      matchBy: action_match_by_payload(op, opts),
      exact: Keyword.get(opts, :exact, false),
      normalizeWs: Keyword.get(opts, :normalize_ws, true),
      count: Keyword.get(opts, :count),
      min: Keyword.get(opts, :min),
      max: Keyword.get(opts, :max),
      between: Keyword.get(opts, :between),
      first: Keyword.get(opts, :first, false),
      last: Keyword.get(opts, :last, false),
      nth: Keyword.get(opts, :nth),
      index: Keyword.get(opts, :index),
      checked: Keyword.get(opts, :checked),
      disabled: Keyword.get(opts, :disabled),
      selected: Keyword.get(opts, :selected),
      readonly: Keyword.get(opts, :readonly),
      visible: Keyword.get(opts, :visible)
    }
  end

  @spec locator(Locator.t()) :: map()
  def locator(%Locator{kind: kind, value: members, opts: opts}) when kind in [:scope, :and, :or, :not] do
    %{
      kind: Atom.to_string(kind),
      members: Enum.map(members, &locator/1),
      opts: locator_opts_payload(opts)
    }
  end

  def locator(%Locator{kind: :css, value: selector, opts: opts}) do
    %{
      kind: "css",
      value: selector,
      opts: locator_opts_payload(opts)
    }
  end

  def locator(%Locator{kind: kind, value: expected, opts: opts}) do
    %{
      kind: Atom.to_string(kind),
      expected: Config.text_expectation_payload(expected),
      opts: locator_opts_payload(opts)
    }
  end

  defp locator_opts_payload(opts) when is_list(opts) do
    %{
      role: Keyword.get(opts, :role),
      exact: Keyword.get(opts, :exact),
      normalizeWs: Keyword.get(opts, :normalize_ws),
      has: nested_locator_payload(Keyword.get(opts, :has)),
      has_not: nested_locator_payload(Keyword.get(opts, :has_not)),
      from: nested_locator_payload(Keyword.get(opts, :from)),
      checked: Keyword.get(opts, :checked),
      disabled: Keyword.get(opts, :disabled),
      selected: Keyword.get(opts, :selected),
      readonly: Keyword.get(opts, :readonly),
      visible: Keyword.get(opts, :visible)
    }
  end

  defp nested_locator_payload(%Locator{} = locator), do: locator(locator)
  defp nested_locator_payload(_other), do: nil

  defp visibility_payload(%Locator{opts: locator_opts}, opts) do
    case Keyword.get(locator_opts, :visible) do
      true -> "visible"
      false -> "hidden"
      _ -> if(Keyword.get(opts, :visible, true), do: "visible", else: "all")
    end
  end

  defp action_kind_payload(:click, opts), do: opts |> Keyword.get(:kind, :any) |> Atom.to_string()
  defp action_kind_payload(_op, _opts), do: nil

  defp action_match_by_payload(op, opts) do
    default =
      if op in [:click, :submit] do
        :text
      else
        :label
      end

    opts
    |> Keyword.get(:match_by, default)
    |> Atom.to_string()
  end
end
