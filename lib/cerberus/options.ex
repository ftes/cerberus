defmodule Cerberus.Options do
  @moduledoc """
  Shared option and option-schema types used by Cerberus public APIs and drivers.

  This module centralizes validation and normalized defaults for operation
  option lists (`click`, `fill_in`, `assert_has`, `submit`, and related helpers).
  """

  @type click_kind :: :any | :link | :button
  @type visibility_filter :: boolean() | :any
  @type fill_in_value :: String.t() | integer() | float() | boolean()

  @type click_opts :: [
          kind: click_kind(),
          selector: String.t() | nil,
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type assert_opts :: [
          visible: visibility_filter(),
          exact: boolean(),
          normalize_ws: boolean(),
          timeout: non_neg_integer()
        ]

  @type fill_in_opts :: [
          selector: String.t() | nil,
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type check_opts :: [
          selector: String.t() | nil,
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type upload_opts :: [
          selector: String.t() | nil,
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type submit_opts :: [
          selector: String.t() | nil,
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type screenshot_opts :: [
          path: String.t() | nil,
          full_page: boolean()
        ]

  @type path_query :: map() | keyword() | nil
  @type path_opts :: [
          exact: boolean(),
          query: path_query()
        ]

  @click_opts_schema [
    kind: [
      type: {:in, [:any, :link, :button]},
      default: :any,
      doc: "Limits click matching to links, buttons, or both."
    ],
    selector: [type: :any, default: nil, doc: "Limits matching to elements that satisfy the CSS selector."],
    exact: [type: :boolean, default: false, doc: "Enables exact text matching."],
    normalize_ws: [type: :boolean, default: true, doc: "Normalizes whitespace before matching."]
  ]

  @assert_opts_schema [
    visible: [
      type: {:in, [true, false, :any]},
      default: true,
      doc: "Chooses visible text only, hidden only, or both."
    ],
    exact: [type: :boolean, default: false, doc: "Enables exact text matching."],
    normalize_ws: [type: :boolean, default: true, doc: "Normalizes whitespace before matching."],
    timeout: [
      type: :non_neg_integer,
      default: 0,
      doc: "Retries text assertions for up to this many milliseconds."
    ]
  ]

  @fill_in_opts_schema [
    selector: [type: :any, default: nil, doc: "Limits field lookup to elements that satisfy the CSS selector."],
    exact: [type: :boolean, default: false, doc: "Enables exact text matching for label lookup."],
    normalize_ws: [
      type: :boolean,
      default: true,
      doc: "Normalizes whitespace before matching labels."
    ]
  ]

  @submit_opts_schema [
    selector: [
      type: :any,
      default: nil,
      doc: "Limits submit control lookup to elements that satisfy the CSS selector."
    ],
    exact: [
      type: :boolean,
      default: false,
      doc: "Enables exact text matching for submit button lookup."
    ],
    normalize_ws: [
      type: :boolean,
      default: true,
      doc: "Normalizes whitespace before matching submit buttons."
    ]
  ]

  @upload_opts_schema [
    selector: [type: :any, default: nil, doc: "Limits file-input lookup to elements that satisfy the CSS selector."],
    exact: [type: :boolean, default: false, doc: "Enables exact text matching for upload label lookup."],
    normalize_ws: [
      type: :boolean,
      default: true,
      doc: "Normalizes whitespace before matching upload labels."
    ]
  ]

  @path_opts_schema [
    exact: [type: :boolean, default: true, doc: "Requires an exact path match unless disabled."],
    query: [
      type: :any,
      default: nil,
      doc: "Optionally validates query params as a subset map/keyword."
    ]
  ]

  @screenshot_opts_schema [
    path: [type: :any, default: nil, doc: "Optional file path for the screenshot output."],
    full_page: [type: :boolean, default: false, doc: "Captures the full document instead of only the viewport."]
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

  @spec path_schema() :: keyword()
  def path_schema, do: @path_opts_schema

  @spec screenshot_schema() :: keyword()
  def screenshot_schema, do: @screenshot_opts_schema

  @spec validate_click!(keyword()) :: click_opts()
  def validate_click!(opts), do: opts |> validate!(@click_opts_schema, "click/3") |> validate_selector!("click/3")

  @spec validate_assert!(keyword(), String.t()) :: assert_opts()
  def validate_assert!(opts, op_name), do: validate!(opts, @assert_opts_schema, op_name)

  @spec validate_fill_in!(keyword()) :: fill_in_opts()
  def validate_fill_in!(opts), do: opts |> validate!(@fill_in_opts_schema, "fill_in/4") |> validate_selector!("fill_in/4")

  @spec validate_check!(keyword(), String.t()) :: check_opts()
  def validate_check!(opts, op_name), do: opts |> validate!(@fill_in_opts_schema, op_name) |> validate_selector!(op_name)

  @spec validate_submit!(keyword()) :: submit_opts()
  def validate_submit!(opts), do: opts |> validate!(@submit_opts_schema, "submit/3") |> validate_selector!("submit/3")

  @spec validate_upload!(keyword()) :: upload_opts()
  def validate_upload!(opts), do: opts |> validate!(@upload_opts_schema, "upload/4") |> validate_selector!("upload/4")

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
end
