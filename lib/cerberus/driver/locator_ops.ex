defmodule Cerberus.Driver.LocatorOps do
  @moduledoc false

  alias Cerberus.Locator

  @spec click(Locator.t(), keyword()) :: {String.t() | Regex.t(), keyword()}
  def click(%Locator{} = locator, opts) when is_list(opts) do
    merged_opts =
      locator
      |> merged_opts(opts)
      |> Keyword.put(:kind, inferred_click_kind(locator))

    clickable_shape(merged_opts, locator)
  end

  @spec submit(Locator.t(), keyword()) :: {String.t() | Regex.t(), keyword()}
  def submit(%Locator{} = locator, opts) when is_list(opts) do
    locator
    |> merged_opts(opts)
    |> clickable_shape(locator)
  end

  @spec form(Locator.t(), keyword()) :: {String.t() | Regex.t(), keyword()}
  def form(%Locator{} = locator, opts) when is_list(opts) do
    locator
    |> merged_opts(opts)
    |> form_shape(locator)
  end

  defp merged_opts(%Locator{opts: locator_opts} = locator, opts) do
    runtime_opts =
      if Locator.contains_kind?(locator, :or) do
        Keyword.put(opts, :count, 1)
      else
        opts
      end

    locator_opts
    |> Keyword.merge(runtime_opts)
    |> Keyword.put(:locator, locator)
  end

  defp clickable_shape(opts, %Locator{kind: kind}) when kind in [:scope, :and, :or, :not] do
    {"", opts}
  end

  defp clickable_shape(opts, %Locator{kind: :role} = locator) do
    resolved_kind = Locator.resolved_kind(locator)
    clickable_shape(opts, %{locator | kind: resolved_kind})
  end

  defp clickable_shape(opts, %Locator{kind: :css, value: _selector}) do
    {"", opts}
  end

  defp clickable_shape(opts, %Locator{kind: :link, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :link)}
  end

  defp clickable_shape(opts, %Locator{kind: :button, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :button)}
  end

  defp clickable_shape(opts, %Locator{kind: :title, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :title)}
  end

  defp clickable_shape(opts, %Locator{kind: :alt, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :alt)}
  end

  defp clickable_shape(opts, %Locator{kind: :aria_label, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :aria_label)}
  end

  defp clickable_shape(opts, %Locator{kind: :testid, value: expected}) do
    normalized_opts =
      opts
      |> Keyword.put(:match_by, :testid)
      |> ensure_exact_opt(true)

    {expected, normalized_opts}
  end

  defp clickable_shape(opts, %Locator{value: expected}) do
    {expected, opts}
  end

  defp form_shape(opts, %Locator{kind: :css, value: _selector}) do
    {"", opts}
  end

  defp form_shape(opts, %Locator{kind: :role} = locator) do
    resolved_kind = Locator.resolved_kind(locator)
    form_shape(opts, %{locator | kind: resolved_kind})
  end

  defp form_shape(opts, %Locator{kind: kind}) when kind in [:scope, :and, :or, :not] do
    {"", opts}
  end

  defp form_shape(opts, %Locator{kind: :placeholder, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :placeholder)}
  end

  defp form_shape(opts, %Locator{kind: :title, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :title)}
  end

  defp form_shape(opts, %Locator{kind: :aria_label, value: expected}) do
    {expected, Keyword.put(opts, :match_by, :aria_label)}
  end

  defp form_shape(opts, %Locator{kind: :testid, value: expected}) do
    normalized_opts =
      opts
      |> Keyword.put(:match_by, :testid)
      |> ensure_exact_opt(true)

    {expected, normalized_opts}
  end

  # Keep non-field locator kinds accepted for form operations.
  # They default to label-like matching and will naturally fail when no candidate matches.
  defp form_shape(opts, %Locator{value: expected}) do
    {expected, opts}
  end

  defp ensure_exact_opt(opts, default) when is_list(opts) and is_boolean(default) do
    if Keyword.has_key?(opts, :exact) do
      opts
    else
      Keyword.put(opts, :exact, default)
    end
  end

  defp inferred_click_kind(%Locator{kind: :link}), do: :link
  defp inferred_click_kind(%Locator{kind: :button}), do: :button

  defp inferred_click_kind(%Locator{kind: :role} = locator) do
    case Locator.resolved_kind(locator) do
      :link -> :link
      :button -> :button
      _ -> :any
    end
  end

  defp inferred_click_kind(%Locator{}), do: :any
end
