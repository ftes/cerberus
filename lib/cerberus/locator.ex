defmodule Cerberus.Locator do
  @moduledoc "Normalize user input into a single internal locator representation."

  alias Cerberus.InvalidLocatorError

  @enforce_keys [:kind, :value]
  defstruct [:kind, :value, opts: []]

  @type locator_kind ::
          :text | :label | :link | :button | :placeholder | :title | :alt | :testid | :css
  @type t :: %__MODULE__{
          kind: locator_kind(),
          value: String.t() | Regex.t(),
          opts: keyword()
        }

  @spec normalize(term()) :: t()
  def normalize(%__MODULE__{} = locator), do: locator
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

  @spec text_sigil(String.t()) :: t()
  def text_sigil(value) when is_binary(value), do: %__MODULE__{kind: :text, value: value}

  @spec sigil(String.t(), charlist()) :: t()
  def sigil(value, modifiers) when is_binary(value) and is_list(modifiers) do
    sigil_opts = parse_sigil_modifiers!(value, modifiers)

    base_locator =
      case sigil_opts.kind do
        :text ->
          %__MODULE__{kind: :text, value: value}

        :css ->
          ensure_css_selector_value!(:css, value, {:l, value, modifiers})
          %__MODULE__{kind: :css, value: value}

        :role ->
          role_name = sigil_opts.role
          role_kind = role_to_kind!(role_name, {:l, value, modifiers})
          %__MODULE__{kind: role_kind, value: parse_role_name!(value, {:l, value, modifiers})}
      end

    exact_opt =
      case sigil_opts.exact do
        :unset -> []
        exact -> [exact: exact]
      end

    %{base_locator | opts: exact_opt}
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
      {:role, key_value(locator_map, :role)},
      {:css, key_value(locator_map, :css)},
      {:testid, key_value(locator_map, :testid)}
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
            "invalid locator #{inspect(original)}; expected one of :text, :label, :link, :button, :placeholder, :title, :alt, :role, :css, or :testid"

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
    ensure_only_keys!(locator_map, original, [:text, :exact, :selector, :has, :from])
    %__MODULE__{kind: :text, value: text, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:label, locator_map, original) do
    label = key_value(locator_map, :label)
    ensure_text_value!(:label, label, original)
    ensure_only_keys!(locator_map, original, [:label, :exact, :selector, :has, :from])
    %__MODULE__{kind: :label, value: label, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:link, locator_map, original) do
    link = key_value(locator_map, :link)
    ensure_text_value!(:link, link, original)
    ensure_only_keys!(locator_map, original, [:link, :exact, :selector, :has, :from])
    %__MODULE__{kind: :link, value: link, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:button, locator_map, original) do
    button = key_value(locator_map, :button)
    ensure_text_value!(:button, button, original)
    ensure_only_keys!(locator_map, original, [:button, :exact, :selector, :has, :from])
    %__MODULE__{kind: :button, value: button, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:placeholder, locator_map, original) do
    placeholder = key_value(locator_map, :placeholder)
    ensure_text_value!(:placeholder, placeholder, original)
    ensure_only_keys!(locator_map, original, [:placeholder, :exact, :selector, :has, :from])
    %__MODULE__{kind: :placeholder, value: placeholder, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:title, locator_map, original) do
    title = key_value(locator_map, :title)
    ensure_text_value!(:title, title, original)
    ensure_only_keys!(locator_map, original, [:title, :exact, :selector, :has, :from])
    %__MODULE__{kind: :title, value: title, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:alt, locator_map, original) do
    alt = key_value(locator_map, :alt)
    ensure_text_value!(:alt, alt, original)
    ensure_only_keys!(locator_map, original, [:alt, :exact, :selector, :has, :from])
    %__MODULE__{kind: :alt, value: alt, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:css, locator_map, original) do
    css = key_value(locator_map, :css)
    ensure_css_selector_value!(:css, css, original)
    ensure_only_keys!(locator_map, original, [:css, :exact, :has, :from])
    %__MODULE__{kind: :css, value: css, opts: locator_opts(locator_map, original)}
  end

  defp normalize_kind(:testid, locator_map, original) do
    testid = key_value(locator_map, :testid)

    if is_binary(testid) and testid != "" do
      ensure_only_keys!(locator_map, original, [:testid, :exact, :has, :from])
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

    ensure_only_keys!(locator_map, original, [:role, :name, :exact, :selector, :has, :from])
    ensure_text_value!(:name, name, original)
    role_name = normalize_role_name!(role, original)
    role_kind = role_to_kind!(role_name, original)
    %__MODULE__{kind: role_kind, value: name, opts: locator_opts(locator_map, original)}
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

  defp normalize_has_locator!(value, original) do
    has_locator = normalize(value)
    ensure_no_nested_has!(has_locator, original)
    ensure_no_nested_from!(has_locator, original, ":has")
    normalize_nested_testid_exact(has_locator)
  end

  defp ensure_no_nested_has!(has_locator, original) do
    if Keyword.has_key?(has_locator.opts, :has) do
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; nested :has locators are not supported"
    end
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
      if Keyword.has_key?(opts, :exact) do
        opts
      else
        Keyword.put(opts, :exact, true)
      end

    %{locator | opts: normalized_opts}
  end

  defp normalize_nested_testid_exact(locator), do: locator

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
    case role do
      value when is_atom(value) ->
        value |> Atom.to_string() |> String.downcase()

      value when is_binary(value) and value != "" ->
        String.downcase(value)

      _ ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; :role must be an atom or string"
    end
  end

  defp role_to_kind!("button", _original), do: :button
  defp role_to_kind!("menuitem", _original), do: :button
  defp role_to_kind!("tab", _original), do: :button
  defp role_to_kind!("link", _original), do: :link
  defp role_to_kind!("textbox", _original), do: :label
  defp role_to_kind!("searchbox", _original), do: :label
  defp role_to_kind!("combobox", _original), do: :label
  defp role_to_kind!("listbox", _original), do: :label
  defp role_to_kind!("spinbutton", _original), do: :label
  defp role_to_kind!("checkbox", _original), do: :label
  defp role_to_kind!("radio", _original), do: :label
  defp role_to_kind!("switch", _original), do: :label
  defp role_to_kind!("img", _original), do: :alt
  defp role_to_kind!("heading", _original), do: :text

  defp role_to_kind!(role_name, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "unsupported :role #{inspect(role_name)} in #{inspect(original)}"
  end

  defp parse_sigil_modifiers!(value, modifiers) do
    Enum.reduce(modifiers, %{kind: :text, role: nil, exact: :unset}, fn modifier, acc ->
      case modifier do
        ?r ->
          role = parse_role_prefix!(value, {:l, value, modifiers})
          put_sigil_kind!(acc, :role, role, {:l, value, modifiers})

        ?c ->
          put_sigil_kind!(acc, :css, nil, {:l, value, modifiers})

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
      message: "invalid locator sigil ~l: use at most one locator-kind modifier (r or c)"
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
end
