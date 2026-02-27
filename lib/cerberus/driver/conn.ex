defmodule Cerberus.Driver.Conn do
  @moduledoc false

  import Phoenix.ConnTest, only: [build_conn: 0, dispatch: 5, recycle: 1]

  @max_redirects 5
  @private_keys_to_preserve [:live_view_connect_params]

  @spec endpoint!(struct() | keyword()) :: module()
  def endpoint!(%{endpoint: endpoint}) when is_atom(endpoint) do
    endpoint
  end

  def endpoint!(session) when is_struct(session) do
    Application.get_env(:cerberus, :endpoint) || missing_endpoint!()
  end

  def endpoint!(opts) when is_list(opts) do
    opts[:endpoint] || Application.get_env(:cerberus, :endpoint) || missing_endpoint!()
  end

  @spec ensure_conn(Plug.Conn.t() | nil) :: Plug.Conn.t()
  def ensure_conn(nil), do: build_conn()
  def ensure_conn(conn), do: recycle_preserving_headers(conn)

  @spec fork_tab_conn(Plug.Conn.t() | nil) :: Plug.Conn.t() | nil
  def fork_tab_conn(nil), do: nil
  def fork_tab_conn(conn), do: ensure_conn(conn)

  @spec fork_user_conn(Plug.Conn.t() | nil) :: Plug.Conn.t() | nil
  def fork_user_conn(nil), do: nil

  def fork_user_conn(conn) do
    conn.req_headers
    |> Enum.reject(fn {name, _value} -> String.downcase(name) == "cookie" end)
    |> Enum.reduce(build_conn(), fn {name, value}, acc ->
      Plug.Conn.put_req_header(acc, name, value)
    end)
    |> preserve_private(conn)
  end

  @spec follow_get(module(), Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def follow_get(endpoint, conn, path) when is_binary(path) do
    do_follow_get(endpoint, conn, path, @max_redirects)
  end

  @spec follow_request(module(), Plug.Conn.t(), atom() | String.t(), String.t(), map()) :: Plug.Conn.t()
  def follow_request(endpoint, conn, method, path, params \\ %{})

  def follow_request(endpoint, conn, method, path, params) when is_binary(path) and is_map(params) do
    method = normalize_method(method)
    do_follow_request(endpoint, conn, method, path, params, @max_redirects)
  end

  @spec current_path(Plug.Conn.t(), String.t() | nil) :: String.t() | nil
  def current_path(conn, fallback \\ nil) do
    case conn.request_path do
      path when is_binary(path) and byte_size(path) > 0 ->
        append_query(path, conn.query_string)

      _ ->
        fallback
    end
  end

  defp do_follow_get(endpoint, conn, path, redirects_left) do
    conn = dispatch(conn, endpoint, :get, path, %{})

    if redirects_left > 0 and redirect?(conn) do
      [location | _] = Plug.Conn.get_resp_header(conn, "location")
      next_path = normalize_location(location)
      do_follow_get(endpoint, recycle_preserving_headers(conn), next_path, redirects_left - 1)
    else
      conn
    end
  end

  defp do_follow_request(endpoint, conn, method, path, params, redirects_left) do
    conn = dispatch(conn, endpoint, method, path, params)

    if redirects_left > 0 and redirect?(conn) do
      [location | _] = Plug.Conn.get_resp_header(conn, "location")
      next_path = normalize_location(location)
      next_method = redirect_method(conn.status, method)
      next_params = if next_method == :get, do: %{}, else: params

      do_follow_request(
        endpoint,
        recycle_preserving_headers(conn),
        next_method,
        next_path,
        next_params,
        redirects_left - 1
      )
    else
      conn
    end
  end

  defp redirect?(conn), do: conn.status in 300..399

  defp normalize_method(method) when is_atom(method) and method in [:get, :post, :put, :patch, :delete], do: method

  defp normalize_method(method) when is_binary(method) do
    method
    |> String.trim()
    |> String.downcase()
    |> case do
      "get" -> :get
      "post" -> :post
      "put" -> :put
      "patch" -> :patch
      "delete" -> :delete
      _ -> :get
    end
  end

  defp normalize_method(_), do: :get

  defp redirect_method(status, method) when status in [307, 308], do: method
  defp redirect_method(_status, _method), do: :get

  defp normalize_location(location) do
    case URI.parse(location) do
      %URI{path: nil} ->
        "/"

      %URI{path: path, query: nil} ->
        path

      %URI{path: path, query: query} ->
        path <> "?" <> query
    end
  end

  defp append_query(path, ""), do: path
  defp append_query(path, nil), do: path
  defp append_query(path, query), do: path <> "?" <> query

  defp recycle_preserving_headers(conn) do
    recycled = recycle(conn)

    recycled
    |> preserve_headers(conn.req_headers)
    |> preserve_private(conn)
  end

  defp preserve_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {name, value}, acc ->
      Plug.Conn.put_req_header(acc, name, value)
    end)
  end

  defp preserve_private(conn, source_conn) do
    Enum.reduce(@private_keys_to_preserve, conn, fn key, acc ->
      case source_conn.private[key] do
        nil -> acc
        value -> Plug.Conn.put_private(acc, key, value)
      end
    end)
  end

  defp missing_endpoint! do
    raise ArgumentError,
          "missing :cerberus, :endpoint configuration; set endpoint in session opts or application env"
  end
end
