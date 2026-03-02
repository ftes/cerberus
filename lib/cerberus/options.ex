defmodule Cerberus.Options do
  @moduledoc """
  Shared option and option-schema types used by Cerberus public APIs and drivers.

  This module centralizes validation and normalized defaults for operation
  option lists (`click`, `fill_in`, `assert_has`, `submit`, and related helpers).
  """

  @type click_kind :: :any | :link | :button
  @type visibility_filter :: boolean() | :any
  @type fill_in_value :: String.t() | integer() | float() | boolean()
  @type select_value :: String.t() | [String.t()]
  @type between_filter :: {non_neg_integer(), non_neg_integer()} | Range.t() | nil

  @type click_opts :: [
          kind: click_kind(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type assert_opts :: [
          visible: visibility_filter(),
          timeout: non_neg_integer(),
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter()
        ]

  @type fill_in_opts :: [
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type check_opts :: [
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type select_opts :: [
          option: select_value(),
          exact_option: boolean(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type choose_opts :: [
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type upload_opts :: [
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type submit_opts :: [
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type screenshot_opts :: [
          path: String.t() | nil,
          full_page: boolean()
        ]

  @type path_query :: map() | keyword() | nil
  @type path_opts :: [
          exact: boolean(),
          query: path_query(),
          timeout: non_neg_integer()
        ]

  @click_opts_schema [
    kind: [
      type: {:in, [:any, :link, :button]},
      default: :any,
      doc: "Limits click matching to links, buttons, or both."
    ],
    selector: [type: :any, default: nil, doc: "Limits matching to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched elements to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched elements to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched elements to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched elements to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @assert_opts_schema [
    visible: [
      type: {:in, [true, false, :any]},
      default: true,
      doc: "Chooses visible text only, hidden only, or both."
    ],
    timeout: [
      type: :non_neg_integer,
      default: 0,
      doc: "Retries text assertions for up to this many milliseconds."
    ],
    count: [type: :any, default: nil, doc: "Requires exactly this many text matches."],
    min: [type: :any, default: nil, doc: "Requires at least this many text matches."],
    max: [type: :any, default: nil, doc: "Requires at most this many text matches."],
    between: [type: :any, default: nil, doc: "Requires text match count to fall within an inclusive range."]
  ]

  @fill_in_opts_schema [
    selector: [type: :any, default: nil, doc: "Limits field lookup to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched fields to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched fields to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched fields to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched fields to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @submit_opts_schema [
    selector: [
      type: :any,
      default: nil,
      doc: "Limits submit control lookup to elements that satisfy the CSS selector."
    ],
    checked: [type: :any, default: nil, doc: "Requires matched submit controls to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched submit controls to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched submit controls to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched submit controls to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @upload_opts_schema [
    selector: [type: :any, default: nil, doc: "Limits file-input lookup to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched file inputs to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched file inputs to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched file inputs to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched file inputs to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @select_opts_schema [
    option: [
      type: :any,
      required: true,
      doc: "Option text to select; for multi-select inputs pass all desired values on each call."
    ],
    exact_option: [type: :boolean, default: true, doc: "Requires exact option-text matches unless disabled."],
    selector: [type: :any, default: nil, doc: "Limits select lookup to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched selects to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched selects to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched selects to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched selects to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @path_opts_schema [
    exact: [type: :boolean, default: true, doc: "Requires an exact path match unless disabled."],
    query: [
      type: :any,
      default: nil,
      doc: "Optionally validates query params as a subset map/keyword."
    ],
    timeout: [
      type: :non_neg_integer,
      default: 0,
      doc: "Retries path assertions for up to this many milliseconds."
    ]
  ]

  @screenshot_opts_schema [
    path: [type: :any, default: nil, doc: "Optional file path for the screenshot output."],
    full_page: [type: :boolean, doc: "Captures the full document instead of only the viewport."]
  ]

  @spec click_schema() :: keyword()
  def click_schema, do: @click_opts_schema

  @spec assert_schema() :: keyword()
  def assert_schema, do: @assert_opts_schema

  @spec fill_in_schema() :: keyword()
  def fill_in_schema, do: @fill_in_opts_schema

  @spec submit_schema() :: keyword()
  def submit_schema, do: @submit_opts_schema

  @spec upload_schema() :: keyword()
  def upload_schema, do: @upload_opts_schema

  @spec select_schema() :: keyword()
  def select_schema, do: @select_opts_schema

  @spec path_schema() :: keyword()
  def path_schema, do: @path_opts_schema

  @spec screenshot_schema() :: keyword()
  def screenshot_schema, do: @screenshot_opts_schema

  @spec validate_click!(keyword()) :: click_opts()
  def validate_click!(opts) do
    opts
    |> validate!(@click_opts_schema, "click/3")
    |> validate_selector!("click/3")
    |> validate_state_filters!("click/3")
    |> validate_match_filters!("click/3", true)
  end

  @spec validate_assert!(keyword(), String.t()) :: assert_opts()
  def validate_assert!(opts, op_name),
    do: opts |> validate!(@assert_opts_schema, op_name) |> validate_match_filters!(op_name, false)

  @spec validate_fill_in!(keyword()) :: fill_in_opts()
  def validate_fill_in!(opts) do
    opts
    |> validate!(@fill_in_opts_schema, "fill_in/4")
    |> validate_selector!("fill_in/4")
    |> validate_state_filters!("fill_in/4")
    |> validate_match_filters!("fill_in/4", true)
  end

  @spec validate_check!(keyword(), String.t()) :: check_opts()
  def validate_check!(opts, op_name) do
    opts
    |> validate!(@fill_in_opts_schema, op_name)
    |> validate_selector!(op_name)
    |> validate_state_filters!(op_name)
    |> validate_match_filters!(op_name, true)
  end

  @spec validate_choose!(keyword(), String.t()) :: choose_opts()
  def validate_choose!(opts, op_name) do
    opts
    |> validate!(@fill_in_opts_schema, op_name)
    |> validate_selector!(op_name)
    |> validate_state_filters!(op_name)
    |> validate_match_filters!(op_name, true)
  end

  @spec validate_select!(keyword()) :: select_opts()
  def validate_select!(opts) do
    opts
    |> validate!(@select_opts_schema, "select/3")
    |> validate_selector!("select/3")
    |> validate_state_filters!("select/3")
    |> validate_match_filters!("select/3", true)
    |> validate_select_option!("select/3")
  end

  @spec validate_submit!(keyword()) :: submit_opts()
  def validate_submit!(opts) do
    opts
    |> validate!(@submit_opts_schema, "submit/3")
    |> validate_selector!("submit/3")
    |> validate_state_filters!("submit/3")
    |> validate_match_filters!("submit/3", true)
  end

  @spec validate_upload!(keyword()) :: upload_opts()
  def validate_upload!(opts) do
    opts
    |> validate!(@upload_opts_schema, "upload/4")
    |> validate_selector!("upload/4")
    |> validate_state_filters!("upload/4")
    |> validate_match_filters!("upload/4", true)
  end

  @spec validate_path!(keyword(), String.t()) :: path_opts()
  def validate_path!(opts, op_name) do
    validated = validate!(opts, @path_opts_schema, op_name)
    query = Keyword.get(validated, :query)

    cond do
      is_nil(query) ->
        validated

      is_map(query) ->
        validated

      Keyword.keyword?(query) ->
        validated

      is_list(query) and Enum.all?(query, &match?({_, _}, &1)) ->
        validated

      true ->
        raise ArgumentError,
              "#{op_name} invalid options: :query must be a map, keyword list, or nil"
    end
  end

  @spec validate_screenshot!(keyword()) :: screenshot_opts()
  def validate_screenshot!(opts) do
    opts
    |> validate!(@screenshot_opts_schema, "screenshot/2")
    |> validate_path_string!("screenshot/2", :path)
  end

  defp validate!(opts, schema, op_name) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError, "#{op_name} invalid options: #{Exception.message(error)}"
    end
  end

  defp validate_selector!(opts, op_name) do
    case Keyword.get(opts, :selector) do
      nil ->
        opts

      selector when is_binary(selector) ->
        if String.trim(selector) == "" do
          raise ArgumentError, "#{op_name} invalid options: :selector must be a non-empty CSS selector string"
        else
          opts
        end

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :selector must be a non-empty CSS selector string"
    end
  end

  defp validate_path_string!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      path when is_binary(path) ->
        if String.trim(path) == "" do
          raise ArgumentError, "#{op_name} invalid options: :#{key} must be a non-empty string path"
        else
          opts
        end

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a non-empty string path"
    end
  end

  defp validate_state_filters!(opts, op_name) do
    opts
    |> validate_boolean_or_nil_opt!(op_name, :checked)
    |> validate_boolean_or_nil_opt!(op_name, :disabled)
    |> validate_boolean_or_nil_opt!(op_name, :selected)
    |> validate_boolean_or_nil_opt!(op_name, :readonly)
  end

  defp validate_boolean_or_nil_opt!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value when is_boolean(value) ->
        opts

      _ ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a boolean or nil"
    end
  end

  defp validate_select_option!(opts, op_name) do
    case Keyword.get(opts, :option) do
      option when is_binary(option) ->
        if String.trim(option) == "" do
          raise ArgumentError,
                "#{op_name} invalid options: :option must be a non-empty string or list of non-empty strings"
        else
          opts
        end

      [_ | _] = options ->
        if Enum.all?(options, &(is_binary(&1) and String.trim(&1) != "")) do
          opts
        else
          raise ArgumentError,
                "#{op_name} invalid options: :option list must contain only non-empty strings"
        end

      [] ->
        raise ArgumentError, "#{op_name} invalid options: :option list must contain at least one value"

      _ ->
        raise ArgumentError, "#{op_name} invalid options: :option must be a non-empty string or list of non-empty strings"
    end
  end

  defp validate_match_filters!(opts, op_name, allow_position?) do
    opts
    |> validate_non_neg_integer_opt!(op_name, :count)
    |> validate_non_neg_integer_opt!(op_name, :min)
    |> validate_non_neg_integer_opt!(op_name, :max)
    |> validate_between_opt!(op_name)
    |> validate_position_opts!(op_name, allow_position?)
  end

  defp validate_non_neg_integer_opt!(opts, op_name, key) when key in [:count, :min, :max] do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value when is_integer(value) and value >= 0 ->
        opts

      _ ->
        raise ArgumentError, key_error_prefix(op_name, key)
    end
  end

  defp validate_between_opt!(opts, op_name) do
    case normalize_between_value(Keyword.get(opts, :between), op_name) do
      nil -> opts
      {min, max} -> Keyword.put(opts, :between, {min, max})
    end
  end

  defp normalize_between_value(nil, _op_name), do: nil

  defp normalize_between_value(%Range{first: first, last: last, step: step}, op_name)
       when is_integer(first) and is_integer(last) and is_integer(step) do
    if first >= 0 and last >= 0 and first <= last and step == 1 do
      {first, last}
    else
      raise ArgumentError,
            "#{op_name} invalid options: :between must be an inclusive ascending range with non-negative bounds"
    end
  end

  defp normalize_between_value({min, max}, _op_name)
       when is_integer(min) and is_integer(max) and min >= 0 and max >= 0 and min <= max do
    {min, max}
  end

  defp normalize_between_value(_other, op_name) do
    raise ArgumentError,
          "#{op_name} invalid options: :between must be a {min, max} tuple or range with non-negative inclusive bounds"
  end

  defp validate_position_opts!(opts, op_name, allow_position?) do
    first = Keyword.get(opts, :first, false)
    last = Keyword.get(opts, :last, false)
    nth = Keyword.get(opts, :nth)
    index = Keyword.get(opts, :index)

    validate_boolean_opt!(op_name, :first, first)
    validate_boolean_opt!(op_name, :last, last)
    validate_nth_opt!(op_name, nth)
    validate_index_opt!(op_name, index)

    active_positions = active_position_filters(first, last, nth, index)
    validate_position_filter_usage!(op_name, allow_position?, active_positions)

    opts
  end

  defp validate_boolean_opt!(op_name, key, value) do
    if not is_boolean(value) do
      raise ArgumentError, "#{op_name} invalid options: :#{key} must be a boolean"
    end
  end

  defp validate_nth_opt!(op_name, nth) do
    if not is_nil(nth) and not (is_integer(nth) and nth > 0) do
      raise ArgumentError, "#{op_name} invalid options: :nth must be a positive integer or nil"
    end
  end

  defp validate_index_opt!(op_name, index) do
    if not is_nil(index) and not (is_integer(index) and index >= 0) do
      raise ArgumentError, "#{op_name} invalid options: :index must be a non-negative integer or nil"
    end
  end

  defp active_position_filters(first, last, nth, index) do
    []
    |> maybe_add_position_flag(:first, first)
    |> maybe_add_position_flag(:last, last)
    |> maybe_add_position_flag(:nth, nth)
    |> maybe_add_position_flag(:index, index)
  end

  defp validate_position_filter_usage!(_op_name, true, []), do: :ok

  defp validate_position_filter_usage!(op_name, false, active_positions) when active_positions != [] do
    raise ArgumentError,
          "#{op_name} invalid options: position filters (:first/:last/:nth/:index) are not supported for this operation"
  end

  defp validate_position_filter_usage!(op_name, _allow_position?, active_positions) when length(active_positions) > 1 do
    raise ArgumentError,
          "#{op_name} invalid options: position filters are mutually exclusive; use only one of :first, :last, :nth, or :index"
  end

  defp validate_position_filter_usage!(_op_name, _allow_position?, _active_positions), do: :ok

  defp maybe_add_position_flag(acc, _name, false), do: acc
  defp maybe_add_position_flag(acc, _name, nil), do: acc
  defp maybe_add_position_flag(acc, name, _value), do: acc ++ [name]

  defp key_error_prefix(op_name, key) do
    "#{op_name} invalid options: :#{key} must be a non-negative integer or nil"
  end
end
