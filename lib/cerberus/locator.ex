defmodule Cerberus.Locator do
  @moduledoc """
  Normalize user input into a canonical locator AST.

  The AST supports:
  - leaf locators (`:text`, `:button`, `:css`, `:testid`, ...)
  - composition (`:and`, `:or`, `:not`)
  - descendant filters via `:has` and `:has_not`
  - closest-scope input via `:from`
  """

  alias Cerberus.InvalidLocatorError

  @enforce_keys [:kind, :value]
  defstruct [:kind, :value, opts: []]

  @type leaf_kind ::
          :text | :label | :link | :button | :placeholder | :title | :alt | :aria_label | :testid | :css
  @type role_kind :: :role
  @type resolved_role_kind :: :text | :label | :link | :button | :alt
  @type composite_kind :: :and | :or | :not
  @type locator_kind :: leaf_kind() | role_kind() | composite_kind()
  @type composite_value :: [t()]
  @type t :: %__MODULE__{
          kind: locator_kind(),
          value: String.t() | Regex.t() | composite_value(),
          opts: keyword()
        }
  @type input :: t() | String.t() | Regex.t() | keyword() | map() | [input()]
  @role_kind_map %{
    "button" => :button,
    "menuitem" => :button,
    "tab" => :button,
    "link" => :link,
    "textbox" => :label,
    "searchbox" => :label,
    "combobox" => :label,
    "listbox" => :label,
    "spinbutton" => :label,
    "checkbox" => :label,
    "radio" => :label,
    "switch" => :label,
    "img" => :alt,
    "heading" => :text
  }

  @spec normalize(term()) :: t()
  def normalize(%__MODULE__{} = locator), do: normalize_locator(locator, locator)
  def normalize(locator) when is_binary(locator), do: %__MODULE__{kind: :text, value: locator}
  def normalize(%Regex{} = locator), do: %__MODULE__{kind: :text, value: locator}

  def normalize(locator) when is_list(locator) do
    if Keyword.keyword?(locator) do
      locator
      |> Map.new()
      |> normalize_map(locator)
    else
      raise InvalidLocatorError, locator: locator
    end
  end

  def normalize(locator) when is_map(locator) do
    normalize_map(locator, locator)
  end

  def normalize(locator), do: raise(InvalidLocatorError, locator: locator)

  @spec leaf(leaf_kind(), String.t() | Regex.t(), keyword()) :: t()
  def leaf(kind, value, opts \\ [])

  def leaf(kind, value, opts) when kind in [:text, :label, :link, :button, :placeholder, :title, :alt, :aria_label] do
    ensure_text_value!(kind, value, {kind, value, opts})
    %__MODULE__{kind: kind, value: value, opts: normalize_leaf_opts(opts, {kind, value, opts})}
  end

  def leaf(:css, value, opts) do
    ensure_css_selector_value!(:css, value, {:css, value, opts})
    %__MODULE__{kind: :css, value: value, opts: normalize_leaf_opts(opts, {:css, value, opts})}
  end

  def leaf(:testid, value, opts) do
    ensure_testid_sigil_value!(value, {:testid, value, opts})

    normalized_opts =
      opts
      |> normalize_leaf_opts({:testid, value, opts})
      |> ensure_exact_opt(true)

    %__MODULE__{kind: :testid, value: value, opts: normalized_opts}
  end

  @spec role(String.t() | atom(), keyword()) :: t()
  def role(role, opts \\ []) when (is_binary(role) or is_atom(role)) and is_list(opts) do
    [role: role, name: Keyword.get(opts, :name)]
    |> maybe_put_opt(opts, :exact)
    |> maybe_put_opt(opts, :selector)
    |> maybe_put_opt(opts, :has)
    |> maybe_put_opt(opts, :has_not)
    |> normalize()
  end

  @spec closest(input(), keyword()) :: t()
  def closest(locator, opts) when is_list(opts) do
    from_locator_input =
      case Keyword.fetch(opts, :from) do
        {:ok, value} -> value
        :error -> raise ArgumentError, "closest/2 expects :from locator option"
      end

    case Keyword.keys(opts) -- [:from] do
      [] ->
        :ok

      extra ->
        raise ArgumentError, "closest/2 supports only :from option, got: #{inspect(extra)}"
    end

    from_locator = normalize(from_locator_input)

    if Keyword.has_key?(from_locator.opts, :from) do
      raise ArgumentError, "closest/2 does not support nested :from locators"
    end

    put_from(locator, from_locator)
  end

  def closest(_locator, _opts) do
    raise ArgumentError, "closest/2 expects keyword options"
  end

  @spec compose_and(input(), input()) :: t()
  def compose_and(left, right) do
    compose(:and, left, right)
  end

  @spec compose_or(input(), input()) :: t()
  def compose_or(left, right) do
    compose(:or, left, right)
  end

  @spec compose_not(input()) :: t()
  def compose_not(locator) do
    %__MODULE__{kind: :not, value: [normalize(locator)], opts: []}
  end

  @spec put_has(input(), input()) :: t()
  def put_has(locator, has_locator) do
    locator = normalize(locator)
    has_locator = normalize(has_locator)
    %{locator | opts: Keyword.put(locator.opts, :has, normalize_nested_testid_exact(has_locator))}
  end

  @spec put_has_not(input(), input()) :: t()
  def put_has_not(locator, has_not_locator) do
    locator = normalize(locator)
    has_not_locator = normalize(has_not_locator)
    %{locator | opts: Keyword.put(locator.opts, :has_not, normalize_nested_testid_exact(has_not_locator))}
  end

  @spec put_from(input(), input()) :: t()
  def put_from(locator, from_locator) do
    locator = normalize(locator)
    from_locator = normalize(from_locator)
    ensure_no_nested_from!(from_locator, {locator, from_locator}, ":from")
    %{locator | opts: Keyword.put(locator.opts, :from, normalize_nested_testid_exact(from_locator))}
  end

  @spec contains_kind?(input(), locator_kind()) :: boolean()
  def contains_kind?(locator, kind)
      when kind in [
             :text,
             :label,
             :link,
             :button,
             :placeholder,
             :title,
             :alt,
             :aria_label,
             :testid,
             :css,
             :role,
             :and,
             :or,
             :not
           ] do
    locator
    |> normalize()
    |> contains_kind_recursive?(kind)
  end

  @spec resolved_kind(t()) :: locator_kind() | resolved_role_kind()
  def resolved_kind(%__MODULE__{kind: :role} = locator) do
    locator
    |> role_name_from_locator!(locator)
    |> resolve_role_kind!(locator)
  end

  def resolved_kind(%__MODULE__{kind: kind}), do: kind

  @spec resolve_role_kind(String.t() | atom()) :: {:ok, resolved_role_kind()} | :error
  def resolve_role_kind(role) do
    with {:ok, role_name} <- normalize_role_name(role),
         {:ok, kind} <- Map.fetch(@role_kind_map, role_name) do
      {:ok, kind}
    else
      _ -> :error
    end
  end

  @spec resolve_role_kind!(String.t() | atom(), term()) :: resolved_role_kind()
  def resolve_role_kind!(role, original) do
    case resolve_role_kind(role) do
      {:ok, kind} ->
        kind

      :error ->
        raise InvalidLocatorError,
          locator: original,
          message: "unsupported :role #{inspect(role)} in #{inspect(original)}"
    end
  end

  @spec contains_has_filter?(input()) :: boolean()
  def contains_has_filter?(locator) do
    locator
    |> normalize()
    |> contains_has_filter_recursive?()
  end

  @spec text_sigil(String.t()) :: t()
  def text_sigil(value) when is_binary(value), do: %__MODULE__{kind: :text, value: value}

  @spec sigil(String.t(), charlist()) :: t()
  def sigil(value, modifiers) when is_binary(value) and is_list(modifiers) do
    sigil_opts = parse_sigil_modifiers!(value, modifiers)
    ensure_text_sigil_mode!(sigil_opts, value, modifiers)
    base_locator = sigil_base_locator!(sigil_opts, value, modifiers)
    opts = Keyword.merge(base_locator.opts, sigil_locator_opts(base_locator.kind, sigil_opts.exact))

    %{base_locator | opts: opts}
  end

  defp ensure_text_sigil_mode!(%{kind: :text, exact: :unset}, value, modifiers) do
    raise InvalidLocatorError,
      locator: {:l, value, modifiers},
      message: "invalid locator sigil ~l: text locators require e or i modifier, e.g. ~l\"Saved\"e"
  end

  defp ensure_text_sigil_mode!(_sigil_opts, _value, _modifiers), do: :ok

  defp sigil_base_locator!(%{kind: :text}, value, _modifiers), do: %__MODULE__{kind: :text, value: value}

  defp sigil_base_locator!(%{kind: :css}, value, modifiers) do
    ensure_css_selector_value!(:css, value, {:l, value, modifiers})
    %__MODULE__{kind: :css, value: value}
  end

  defp sigil_base_locator!(%{kind: :testid}, value, modifiers) do
    ensure_testid_sigil_value!(value, {:l, value, modifiers})
    %__MODULE__{kind: :testid, value: value}
  end

  defp sigil_base_locator!(%{kind: :aria_label}, value, modifiers) do
    ensure_text_value!(:aria_label, value, {:l, value, modifiers})
    %__MODULE__{kind: :aria_label, value: value}
  end

  defp sigil_base_locator!(%{kind: :role, role: role_name}, value, modifiers) do
    normalized_role = normalize_role_name!(role_name, {:l, value, modifiers})
    resolve_role_kind!(normalized_role, {:l, value, modifiers})

    %__MODULE__{
      kind: :role,
      value: parse_role_name!(value, {:l, value, modifiers}),
      opts: [role: normalized_role]
    }
  end

  defp sigil_locator_opts(:testid, exact) do
    exact_opt =
      case exact do
        :unset -> []
        exact_value -> [exact: exact_value]
      end

    ensure_exact_opt(exact_opt, true)
  end

  defp sigil_locator_opts(_kind, exact) do
    case exact do
      :unset -> []
      exact_value -> [exact: exact_value]
    end
  end

  defp normalize_map(locator_map, original) do
    kinds = [
      {:text, key_value(locator_map, :text)},
      {:label, key_value(locator_map, :label)},
      {:link, key_value(locator_map, :link)},
      {:button, key_value(locator_map, :button)},
      {:placeholder, key_value(locator_map, :placeholder)},
      {:title, key_value(locator_map, :title)},
      {:alt, key_value(locator_map, :alt)},
      {:aria_label, key_value(locator_map, :aria_label)},
      {:role, key_value(locator_map, :role)},
      {:css, key_value(locator_map, :css)},
      {:testid, key_value(locator_map, :testid)},
      {:and, key_value(locator_map, :and)},
      {:or, key_value(locator_map, :or)},
      {:not, key_value(locator_map, :not)}
    ]

    present =
      kinds
      |> Enum.filter(fn {_kind, value} -> value != :__missing__ end)
      |> Enum.map(fn {kind, _value} -> kind end)

    case present do
      [] ->
        raise InvalidLocatorError,
          locator: original,
          message:
            "invalid locator #{inspect(original)}; expected one of :text, :label, :link, :button, :placeholder, :title, :alt, :aria_label, :role, :css, :testid, :and, :or, or :not"

      [kind] ->
        normalize_kind(kind, locator_map, original)

      many ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; expected exactly one locator kind key, got #{inspect(many)}"
    end
  end

  defp normalize_kind(:text, locator_map, original) do
    text = key_value(locator_map, :text)
    ensure_text_value!(:text, text, original)
    ensure_only_keys!(locator_map, original, [:text, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :text, value: text, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:and, locator_map, original) do
    and_value = key_value(locator_map, :and)
    ensure_only_keys!(locator_map, original, [:and])
    normalize_composite(:and, and_value, original)
  end

  defp normalize_kind(:or, locator_map, original) do
    or_value = key_value(locator_map, :or)
    ensure_only_keys!(locator_map, original, [:or])
    normalize_composite(:or, or_value, original)
  end

  defp normalize_kind(:not, locator_map, original) do
    not_value = key_value(locator_map, :not)
    ensure_only_keys!(locator_map, original, [:not])
    normalize_composite(:not, not_value, original)
  end

  defp normalize_kind(:label, locator_map, original) do
    label = key_value(locator_map, :label)
    ensure_text_value!(:label, label, original)
    ensure_only_keys!(locator_map, original, [:label, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :label, value: label, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:link, locator_map, original) do
    link = key_value(locator_map, :link)
    ensure_text_value!(:link, link, original)
    ensure_only_keys!(locator_map, original, [:link, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :link, value: link, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:button, locator_map, original) do
    button = key_value(locator_map, :button)
    ensure_text_value!(:button, button, original)
    ensure_only_keys!(locator_map, original, [:button, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :button, value: button, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:placeholder, locator_map, original) do
    placeholder = key_value(locator_map, :placeholder)
    ensure_text_value!(:placeholder, placeholder, original)
    ensure_only_keys!(locator_map, original, [:placeholder, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :placeholder, value: placeholder, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:title, locator_map, original) do
    title = key_value(locator_map, :title)
    ensure_text_value!(:title, title, original)
    ensure_only_keys!(locator_map, original, [:title, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :title, value: title, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:alt, locator_map, original) do
    alt = key_value(locator_map, :alt)
    ensure_text_value!(:alt, alt, original)
    ensure_only_keys!(locator_map, original, [:alt, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :alt, value: alt, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:aria_label, locator_map, original) do
    aria_label = key_value(locator_map, :aria_label)
    ensure_text_value!(:aria_label, aria_label, original)
    ensure_only_keys!(locator_map, original, [:aria_label, :exact, :selector, :has, :has_not, :from])
    %__MODULE__{kind: :aria_label, value: aria_label, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:css, locator_map, original) do
    css = key_value(locator_map, :css)
    ensure_css_selector_value!(:css, css, original)
    ensure_only_keys!(locator_map, original, [:css, :exact, :has, :has_not, :from])
    %__MODULE__{kind: :css, value: css, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:testid, locator_map, original) do
    testid = key_value(locator_map, :testid)

    if is_binary(testid) and testid != "" do
      ensure_only_keys!(locator_map, original, [:testid, :exact, :has, :has_not, :from])
      %__MODULE__{kind: :testid, value: testid, opts: locator_opts(locator_map, original)}
    else
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; :testid must be a non-empty string"
    end
  end

  defp normalize_kind(:role, locator_map, original) do
    role = key_value(locator_map, :role)
    name = key_value(locator_map, :name)

    ensure_only_keys!(locator_map, original, [:role, :name, :exact, :selector, :has, :has_not, :from])
    ensure_text_value!(:name, name, original)
    role_name = normalize_role_name!(role, original)
    resolve_role_kind!(role_name, original)
    %__MODULE__{kind: :role, value: name, opts: locator_map |> locator_opts(original) |> Keyword.put(:role, role_name)}
  end

  defp key_value(locator_map, key) when is_atom(key) do
    Map.get(locator_map, key, Map.get(locator_map, Atom.to_string(key), :__missing__))
  end

  defp ensure_text_value!(name, value, original) do
    if is_binary(value) or is_struct(value, Regex) do
      :ok
    else
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; #{inspect(name)} must be a string or regex"
    end
  end

  defp ensure_css_selector_value!(name, value, original) do
    if is_binary(value) and String.trim(value) != "" do
      :ok
    else
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; #{inspect(name)} must be a non-empty CSS selector string"
    end
  end

  defp locator_opts(locator_map, original) do
    []
    |> maybe_put_exact(locator_map, original)
    |> maybe_put_selector(locator_map, original)
    |> maybe_put_has(locator_map, original)
    |> maybe_put_has_not(locator_map, original)
    |> maybe_put_from(locator_map, original)
  end

  defp maybe_put_exact(opts, locator_map, original) do
    case key_value(locator_map, :exact) do
      :__missing__ ->
        opts

      exact when is_boolean(exact) ->
        Keyword.put(opts, :exact, exact)

      _other ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; :exact must be a boolean"
    end
  end

  defp maybe_put_selector(opts, locator_map, original) do
    case key_value(locator_map, :selector) do
      :__missing__ ->
        opts

      selector when is_binary(selector) ->
        if String.trim(selector) == "" do
          raise InvalidLocatorError,
            locator: original,
            message: "invalid locator #{inspect(original)}; :selector must be a non-empty CSS selector string"
        else
          Keyword.put(opts, :selector, selector)
        end

      _other ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; :selector must be a non-empty CSS selector string"
    end
  end

  defp maybe_put_has(opts, locator_map, original) do
    case key_value(locator_map, :has) do
      :__missing__ ->
        opts

      has_locator_input ->
        Keyword.put(opts, :has, normalize_has_locator!(has_locator_input, original))
    end
  end

  defp maybe_put_has_not(opts, locator_map, original) do
    case key_value(locator_map, :has_not) do
      :__missing__ ->
        opts

      has_not_locator_input ->
        Keyword.put(opts, :has_not, normalize_has_locator!(has_not_locator_input, original))
    end
  end

  defp normalize_has_locator!(value, original) do
    has_locator = normalize(value)
    ensure_no_nested_from!(has_locator, original, ":has")
    normalize_nested_testid_exact(has_locator)
  end

  defp maybe_put_from(opts, locator_map, original) do
    case key_value(locator_map, :from) do
      :__missing__ ->
        opts

      from_locator_input ->
        Keyword.put(opts, :from, normalize_from_locator!(from_locator_input, original))
    end
  end

  defp normalize_from_locator!(value, original) do
    from_locator = normalize(value)
    ensure_no_nested_from!(from_locator, original, ":from")
    normalize_nested_testid_exact(from_locator)
  end

  defp ensure_no_nested_from!(locator, original, key) do
    if Keyword.has_key?(locator.opts, :from) do
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; nested #{key} locators are not supported"
    end
  end

  defp normalize_nested_testid_exact(%__MODULE__{kind: :testid, opts: opts} = locator) do
    normalized_opts =
      ensure_exact_opt(opts, true)

    %{locator | opts: normalized_opts}
  end

  defp normalize_nested_testid_exact(locator), do: locator

  defp normalize_composite(kind, value, original) when kind in [:and, :or] do
    members =
      value
      |> compose_members!(kind, original)
      |> Enum.map(&normalize/1)
      |> Enum.flat_map(&flatten_composite_members(kind, &1))

    if length(members) < 2 do
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; :#{kind} expects at least two locator entries"
    end

    %__MODULE__{kind: kind, value: members, opts: []}
  end

  defp normalize_composite(:not, value, _original) do
    member = normalize(value)
    %__MODULE__{kind: :not, value: [member], opts: []}
  end

  defp compose_members!(value, _kind, _original) when is_list(value), do: value

  defp compose_members!(_value, kind, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator #{inspect(original)}; :#{kind} expects a list of locator entries"
  end

  defp flatten_composite_members(kind, %__MODULE__{kind: member_kind, value: value})
       when is_list(value) and member_kind == kind, do: value

  defp flatten_composite_members(_kind, locator), do: [locator]

  defp ensure_only_keys!(locator_map, original, allowed_atom_keys) do
    allowed =
      allowed_atom_keys
      |> Enum.flat_map(fn key -> [key, Atom.to_string(key)] end)
      |> MapSet.new()

    case locator_map |> Map.keys() |> Enum.reject(&MapSet.member?(allowed, &1)) do
      [] ->
        :ok

      extra ->
        raise InvalidLocatorError,
          locator: original,
          message: "unsupported locator keys #{inspect(extra)} in #{inspect(original)}"
    end
  end

  defp normalize_role_name!(role, original) do
    case normalize_role_name(role) do
      {:ok, role_name} ->
        role_name

      :error ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; :role must be an atom or string"
    end
  end

  defp normalize_role_name(role) do
    case role do
      value when is_atom(value) ->
        {:ok, value |> Atom.to_string() |> String.downcase()}

      value when is_binary(value) and value != "" ->
        {:ok, String.downcase(value)}

      _ ->
        :error
    end
  end

  defp parse_sigil_modifiers!(value, modifiers) do
    Enum.reduce(modifiers, %{kind: :text, role: nil, exact: :unset}, fn modifier, acc ->
      case modifier do
        ?r ->
          role = parse_role_prefix!(value, {:l, value, modifiers})
          put_sigil_kind!(acc, :role, role, {:l, value, modifiers})

        ?c ->
          put_sigil_kind!(acc, :css, nil, {:l, value, modifiers})

        ?a ->
          put_sigil_kind!(acc, :aria_label, nil, {:l, value, modifiers})

        ?t ->
          put_sigil_kind!(acc, :testid, nil, {:l, value, modifiers})

        ?e ->
          put_sigil_exact!(acc, true, {:l, value, modifiers})

        ?i ->
          put_sigil_exact!(acc, false, {:l, value, modifiers})

        other ->
          raise InvalidLocatorError,
            locator: {:l, value, modifiers},
            message: "invalid locator sigil ~l: unsupported modifier #{inspect(<<other>>)}"
      end
    end)
  end

  defp put_sigil_kind!(%{kind: current} = acc, kind, role, _original) when current in [:text, kind] do
    %{acc | kind: kind, role: role || acc.role}
  end

  defp put_sigil_kind!(_acc, _kind, _role, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator sigil ~l: use at most one locator-kind modifier (r, c, a, or t)"
  end

  defp put_sigil_exact!(%{exact: :unset} = acc, exact, _original), do: %{acc | exact: exact}
  defp put_sigil_exact!(%{exact: exact} = acc, exact, _original), do: acc

  defp put_sigil_exact!(_acc, _exact, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator sigil ~l: modifiers e and i are mutually exclusive"
  end

  defp parse_role_prefix!(value, original) do
    case String.split(value, ":", parts: 2) do
      [raw_role, raw_name] ->
        role = String.downcase(String.trim(raw_role))
        name = String.trim(raw_name)

        if role != "" and name != "" do
          role
        else
          raise InvalidLocatorError,
            locator: original,
            message: "invalid locator sigil ~l: role modifier expects ROLE:NAME text, e.g. ~l\"button:Save\"r"
        end

      _ ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator sigil ~l: role modifier expects ROLE:NAME text, e.g. ~l\"button:Save\"r"
    end
  end

  defp parse_role_name!(value, original) do
    case String.split(value, ":", parts: 2) do
      [_role, raw_name] ->
        String.trim(raw_name)

      _ ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator sigil ~l: role modifier expects ROLE:NAME text, e.g. ~l\"button:Save\"r"
    end
  end

  defp ensure_testid_sigil_value!(value, original) do
    if value == "" do
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator sigil ~l: testid modifier expects non-empty text, e.g. ~l\"search-input\"t"
    else
      :ok
    end
  end

  defp ensure_exact_opt(opts, default) when is_list(opts) do
    if Keyword.has_key?(opts, :exact) do
      opts
    else
      Keyword.put(opts, :exact, default)
    end
  end

  defp compose(kind, left, right) when kind in [:and, :or] do
    left = normalize(left)
    right = normalize(right)

    members = Enum.flat_map([left, right], &flatten_composite_members(kind, &1))

    %__MODULE__{kind: kind, value: members, opts: []}
  end

  defp normalize_locator(%__MODULE__{kind: kind, value: members, opts: opts} = locator, original)
       when kind in [:and, :or] do
    members =
      members
      |> compose_members!(kind, original)
      |> Enum.map(&normalize_locator(normalize(&1), original))
      |> Enum.flat_map(&flatten_composite_members(kind, &1))

    if length(members) < 2 do
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; composed locators require at least two members"
    end

    %{locator | value: members, opts: normalize_composite_opts(opts, original)}
  end

  defp normalize_locator(%__MODULE__{kind: :not, value: value, opts: opts} = locator, original) do
    member =
      case value do
        [%__MODULE__{} = locator_member] ->
          normalize_locator(normalize(locator_member), original)

        [locator_member] ->
          normalize(locator_member)

        %__MODULE__{} = locator_member ->
          normalize_locator(normalize(locator_member), original)

        locator_member ->
          normalize(locator_member)
      end

    %{locator | value: [member], opts: normalize_composite_opts(opts, original)}
  end

  defp normalize_locator(%__MODULE__{kind: kind, value: value, opts: opts} = locator, original)
       when kind in [:text, :label, :link, :button, :placeholder, :title, :alt, :aria_label] do
    ensure_text_value!(kind, value, original)
    %{locator | opts: normalize_leaf_opts(opts, original)}
  end

  defp normalize_locator(%__MODULE__{kind: :role, value: value, opts: opts} = locator, original) do
    ensure_text_value!(:name, value, original)
    %{locator | opts: normalize_role_opts(opts, original)}
  end

  defp normalize_locator(%__MODULE__{kind: :css, value: value, opts: opts} = locator, original) do
    ensure_css_selector_value!(:css, value, original)
    %{locator | opts: normalize_leaf_opts(opts, original)}
  end

  defp normalize_locator(%__MODULE__{kind: :testid, value: value, opts: opts} = locator, original) do
    ensure_testid_sigil_value!(value, original)

    normalized_opts =
      opts
      |> normalize_leaf_opts(original)
      |> ensure_exact_opt(true)

    %{locator | opts: normalized_opts}
  end

  defp normalize_locator(%__MODULE__{kind: kind}, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator #{inspect(original)}; unsupported locator kind #{inspect(kind)}"
  end

  defp maybe_put_opt(locator, opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> Keyword.put(locator, key, value)
      :error -> locator
    end
  end

  defp normalize_leaf_opts(opts, original) when is_list(opts) do
    opts_map = Map.new(opts)
    ensure_only_keys!(opts_map, original, [:exact, :selector, :has, :has_not, :from])
    locator_opts(opts_map, original)
  end

  defp normalize_leaf_opts(_opts, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator #{inspect(original)}; :opts must be a keyword list"
  end

  defp normalize_role_opts(opts, original) when is_list(opts) do
    opts_map = Map.new(opts)
    ensure_only_keys!(opts_map, original, [:role, :exact, :selector, :has, :has_not, :from])

    role_name =
      case key_value(opts_map, :role) do
        :__missing__ ->
          raise InvalidLocatorError,
            locator: original,
            message: "invalid locator #{inspect(original)}; :role locator is missing :role metadata"

        role ->
          normalize_role_name!(role, original)
      end

    resolve_role_kind!(role_name, original)
    opts_map |> locator_opts(original) |> Keyword.put(:role, role_name)
  end

  defp normalize_role_opts(_opts, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator #{inspect(original)}; :opts must be a keyword list"
  end

  defp normalize_composite_opts(opts, original) when is_list(opts) do
    opts_map = Map.new(opts)
    ensure_only_keys!(opts_map, original, [:has, :has_not, :from])

    []
    |> maybe_put_has(opts_map, original)
    |> maybe_put_has_not(opts_map, original)
    |> maybe_put_from(opts_map, original)
  end

  defp normalize_composite_opts(_opts, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "invalid locator #{inspect(original)}; composed locator opts must be a keyword list"
  end

  defp contains_kind_recursive?(%__MODULE__{kind: kind}, kind), do: true

  defp contains_kind_recursive?(%__MODULE__{kind: composite_kind, value: members}, kind)
       when composite_kind in [:and, :or, :not] and is_list(members) do
    Enum.any?(members, &contains_kind_recursive?(&1, kind))
  end

  defp contains_kind_recursive?(_locator, _kind), do: false

  defp contains_has_filter_recursive?(%__MODULE__{kind: composite_kind, value: members, opts: opts})
       when composite_kind in [:and, :or, :not] and is_list(members) do
    Keyword.has_key?(opts, :has) or Keyword.has_key?(opts, :has_not) or
      Enum.any?(members, &contains_has_filter_recursive?/1)
  end

  defp contains_has_filter_recursive?(%__MODULE__{opts: opts}) when is_list(opts) do
    match?(%__MODULE__{}, Keyword.get(opts, :has)) or match?(%__MODULE__{}, Keyword.get(opts, :has_not))
  end

  defp role_name_from_locator!(%__MODULE__{opts: opts}, original) do
    role =
      case Keyword.get(opts, :role) do
        nil ->
          raise InvalidLocatorError,
            locator: original,
            message: "invalid locator #{inspect(original)}; :role locator is missing :role metadata"

        value ->
          value
      end

    normalize_role_name!(role, original)
  end
end
