defmodule Cerberus.Options do
  @moduledoc false

  @type click_kind :: :any | :link | :button
  @type visibility_filter :: true | false | :any
  @type fill_in_value :: String.t() | integer() | float() | boolean()

  @type click_opts :: [
          kind: click_kind(),
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type assert_opts :: [
          visible: visibility_filter(),
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type fill_in_opts :: [
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @type submit_opts :: [
          exact: boolean(),
          normalize_ws: boolean()
        ]

  @click_opts_schema [
    kind: [
      type: {:in, [:any, :link, :button]},
      default: :any,
      doc: "Limits click matching to links, buttons, or both."
    ],
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
    normalize_ws: [type: :boolean, default: true, doc: "Normalizes whitespace before matching."]
  ]

  @fill_in_opts_schema [
    exact: [type: :boolean, default: false, doc: "Enables exact text matching for label lookup."],
    normalize_ws: [
      type: :boolean,
      default: true,
      doc: "Normalizes whitespace before matching labels."
    ]
  ]

  @submit_opts_schema [
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

  @spec click_schema() :: keyword()
  def click_schema, do: @click_opts_schema

  @spec assert_schema() :: keyword()
  def assert_schema, do: @assert_opts_schema

  @spec fill_in_schema() :: keyword()
  def fill_in_schema, do: @fill_in_opts_schema

  @spec submit_schema() :: keyword()
  def submit_schema, do: @submit_opts_schema

  @spec validate_click!(keyword()) :: click_opts()
  def validate_click!(opts), do: validate!(opts, @click_opts_schema, "click/3")

  @spec validate_assert!(keyword(), String.t()) :: assert_opts()
  def validate_assert!(opts, op_name), do: validate!(opts, @assert_opts_schema, op_name)

  @spec validate_fill_in!(keyword()) :: fill_in_opts()
  def validate_fill_in!(opts), do: validate!(opts, @fill_in_opts_schema, "fill_in/4")

  @spec validate_submit!(keyword()) :: submit_opts()
  def validate_submit!(opts), do: validate!(opts, @submit_opts_schema, "submit/3")

  defp validate!(opts, schema, op_name) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError, "#{op_name} invalid options: #{Exception.message(error)}"
    end
  end
end
