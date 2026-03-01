defmodule Cerberus.Driver.Browser.Config do
  @moduledoc false

  alias Cerberus.Driver.Browser.AssertionHelpers
  alias Cerberus.Driver.Browser.PopupHelpers

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @default_screenshot_full_page false

  @type viewport :: %{width: pos_integer(), height: pos_integer()}
  @type browser_context_defaults :: %{
          viewport: viewport() | nil,
          user_agent: String.t() | nil,
          init_scripts: [String.t()],
          popup_mode: :allow | :same_tab
        }

  @spec screenshot_path(keyword()) :: String.t()
  def screenshot_path(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    case Keyword.get(opts, :path) do
      path when is_binary(path) -> path
      nil -> configured_screenshot_path(browser_opts) || default_screenshot_path(browser_opts)
      path -> path
    end
  end

  @spec screenshot_full_page(keyword()) :: boolean()
  def screenshot_full_page(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    opts
    |> Keyword.get(:full_page, browser_opts[:screenshot_full_page])
    |> normalize_boolean(@default_screenshot_full_page)
  end

  @spec browser_context_defaults(keyword()) :: browser_context_defaults()
  def browser_context_defaults(opts) when is_list(opts) do
    case Keyword.get(opts, :browser_context_defaults) do
      %{} = defaults ->
        normalize_browser_context_defaults!(defaults)

      nil ->
        browser_opts = merged_browser_opts(opts)
        popup_mode = normalize_popup_mode(opt_value(opts, browser_opts, :popup_mode))

        %{
          viewport: normalize_viewport(opt_value(opts, browser_opts, :viewport)),
          user_agent: normalize_user_agent(opt_value(opts, browser_opts, :user_agent)),
          popup_mode: popup_mode,
          init_scripts:
            opts
            |> opt_value(browser_opts, :init_scripts)
            |> normalize_init_scripts(opt_value(opts, browser_opts, :init_script))
            |> ensure_internal_init_scripts(popup_mode)
        }

      other ->
        raise ArgumentError, ":browser_context_defaults must be a map, got: #{inspect(other)}"
    end
  end

  @spec ready_timeout_ms(keyword()) :: pos_integer()
  def ready_timeout_ms(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    opts
    |> Keyword.get(:ready_timeout_ms, browser_opts[:ready_timeout_ms])
    |> normalize_positive_integer(@default_ready_timeout_ms)
  end

  @spec ready_quiet_ms(keyword()) :: pos_integer()
  def ready_quiet_ms(opts) when is_list(opts) do
    browser_opts = merged_browser_opts(opts)

    opts
    |> Keyword.get(:ready_quiet_ms, browser_opts[:ready_quiet_ms])
    |> normalize_positive_integer(@default_ready_quiet_ms)
  end

  @spec visibility_filter(keyword()) :: true | false | :any
  def visibility_filter(opts) when is_list(opts) do
    case Keyword.get(opts, :visible, true) do
      :any -> :any
      false -> false
      _ -> true
    end
  end

  @spec assertion_timeout_ms(keyword()) :: non_neg_integer()
  def assertion_timeout_ms(opts) when is_list(opts) do
    case Keyword.get(opts, :timeout, 0) do
      timeout when is_integer(timeout) and timeout >= 0 -> timeout
      _ -> 0
    end
  end

  @spec path_timeout_ms(keyword()) :: non_neg_integer()
  def path_timeout_ms(opts) when is_list(opts) do
    case Keyword.get(opts, :timeout, 0) do
      timeout when is_integer(timeout) and timeout >= 0 -> timeout
      _ -> 0
    end
  end

  @spec command_timeout_ms(non_neg_integer()) :: pos_integer()
  def command_timeout_ms(timeout_ms) when is_integer(timeout_ms) and timeout_ms >= 0 do
    max(timeout_ms, 1_000) + 5_000
  end

  @spec text_expectation_payload(String.t() | Regex.t()) :: map()
  def text_expectation_payload(%Regex{source: source, opts: opts}) do
    %{"type" => "regex", "source" => source, "opts" => opts}
  end

  def text_expectation_payload(expected) when is_binary(expected) do
    %{"type" => "string", "value" => expected}
  end

  @spec path_expectation_payload(String.t() | Regex.t()) :: map()
  def path_expectation_payload(%Regex{source: source, opts: opts}) do
    %{"type" => "regex", "source" => source, "opts" => opts}
  end

  def path_expectation_payload(expected) when is_binary(expected) do
    %{"type" => "string", "value" => expected}
  end

  @spec visibility_mode(true | false | :any) :: String.t()
  def visibility_mode(true), do: "visible"
  def visibility_mode(false), do: "hidden"
  def visibility_mode(:any), do: "any"

  @spec ensure_popup_mode_supported!(:chrome | :firefox, :allow | :same_tab) :: :ok
  def ensure_popup_mode_supported!(:firefox, :same_tab) do
    raise ArgumentError,
          "popup_mode :same_tab is currently unsupported on Firefox due a WebDriver BiDi preload runtime issue; use :allow on Firefox"
  end

  def ensure_popup_mode_supported!(_browser_name, _popup_mode), do: :ok

  defp default_screenshot_path(browser_opts) do
    artifact_dir =
      browser_opts
      |> Keyword.get(:screenshot_artifact_dir)
      |> normalize_non_empty_string(System.tmp_dir!())

    Path.join([artifact_dir, "cerberus-screenshot#{System.unique_integer([:monotonic])}.png"])
  end

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp normalize_boolean(value, _default) when is_boolean(value), do: value
  defp normalize_boolean(_value, default), do: default

  defp normalize_non_empty_string(value, default) when is_binary(value) do
    if byte_size(String.trim(value)) > 0, do: value, else: default
  end

  defp normalize_non_empty_string(_value, default), do: default

  defp configured_screenshot_path(browser_opts) do
    case Keyword.get(browser_opts, :screenshot_path) do
      path when is_binary(path) ->
        if byte_size(String.trim(path)) > 0, do: path

      _ ->
        nil
    end
  end

  defp normalize_browser_context_defaults!(defaults) when is_map(defaults) do
    popup_mode = normalize_popup_mode(Map.get(defaults, :popup_mode))

    %{
      viewport: normalize_viewport(Map.get(defaults, :viewport)),
      user_agent: normalize_user_agent(Map.get(defaults, :user_agent)),
      popup_mode: popup_mode,
      init_scripts:
        defaults
        |> Map.get(:init_scripts)
        |> normalize_init_scripts(nil)
        |> ensure_internal_init_scripts(popup_mode)
    }
  end

  defp ensure_internal_init_scripts(scripts, popup_mode) when is_list(scripts) do
    popup_script =
      case popup_mode do
        :same_tab -> [PopupHelpers.same_tab_popup_preload_script()]
        :allow -> []
      end

    [AssertionHelpers.preload_script() | popup_script] ++ scripts
  end

  defp merged_browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp opt_value(opts, browser_opts, key) do
    if Keyword.has_key?(opts, key), do: Keyword.get(opts, key), else: Keyword.get(browser_opts, key)
  end

  defp normalize_viewport(nil), do: nil

  defp normalize_viewport({width, height}) when is_integer(width) and is_integer(height) do
    viewport_dimensions!(width, height)
  end

  defp normalize_viewport(%{width: width, height: height}) when is_integer(width) and is_integer(height) do
    viewport_dimensions!(width, height)
  end

  defp normalize_viewport(viewport) when is_list(viewport) do
    width = Keyword.get(viewport, :width)
    height = Keyword.get(viewport, :height)

    if is_integer(width) and is_integer(height) do
      viewport_dimensions!(width, height)
    else
      raise ArgumentError,
            ":viewport must include integer :width and :height values, got: #{inspect(viewport)}"
    end
  end

  defp normalize_viewport(viewport) do
    raise ArgumentError, ":viewport must be nil, {width, height}, map, or keyword list, got: #{inspect(viewport)}"
  end

  defp viewport_dimensions!(width, height) when width > 0 and height > 0 do
    %{width: width, height: height}
  end

  defp viewport_dimensions!(width, height) do
    raise ArgumentError, ":viewport dimensions must be positive integers, got: {#{inspect(width)}, #{inspect(height)}}"
  end

  defp normalize_user_agent(nil), do: nil

  defp normalize_user_agent(user_agent) when is_binary(user_agent) do
    if String.trim(user_agent) == "" do
      raise ArgumentError, ":user_agent must be a non-empty string"
    else
      user_agent
    end
  end

  defp normalize_user_agent(user_agent) do
    raise ArgumentError, ":user_agent must be a string, got: #{inspect(user_agent)}"
  end

  defp normalize_popup_mode(nil), do: :allow
  defp normalize_popup_mode(:allow), do: :allow
  defp normalize_popup_mode(:same_tab), do: :same_tab

  defp normalize_popup_mode(mode) do
    raise ArgumentError, ":popup_mode must be :allow or :same_tab, got: #{inspect(mode)}"
  end

  defp normalize_init_scripts(scripts, script) do
    scripts_from(scripts, :init_scripts) ++ scripts_from(script, :init_script)
  end

  defp scripts_from(nil, _label), do: []

  defp scripts_from(value, _label) when is_binary(value) do
    script = String.trim(value)

    if script == "" do
      raise ArgumentError, ":init_scripts and :init_script values must be non-empty strings"
    else
      [value]
    end
  end

  defp scripts_from(values, label) when is_list(values) do
    Enum.map(values, fn
      value when is_binary(value) ->
        if String.trim(value) == "" do
          raise ArgumentError, ":#{label} entries must be non-empty strings"
        else
          value
        end

      value ->
        raise ArgumentError, ":#{label} must contain only strings, got: #{inspect(value)}"
    end)
  end

  defp scripts_from(value, label) do
    raise ArgumentError, ":#{label} must be a string or list of strings, got: #{inspect(value)}"
  end
end
