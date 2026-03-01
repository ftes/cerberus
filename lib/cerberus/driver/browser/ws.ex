defmodule Cerberus.Driver.Browser.WS do
  @moduledoc false

  use GenServer

  import Bitwise

  @connect_timeout_ms 6_000
  @handshake_timeout_ms 5_000

  @type owner_event ::
          {:cerberus_bidi_connected, pid()}
          | {:cerberus_bidi_frame, pid(), binary()}
          | {:cerberus_bidi_disconnected, pid(), term()}

  @spec start_link(String.t(), pid(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(url, owner, opts \\ []) when is_binary(url) and is_pid(owner) and is_list(opts) do
    GenServer.start_link(__MODULE__, {url, owner, opts})
  end

  @spec send_text(pid(), binary()) :: :ok
  def send_text(pid, payload) when is_pid(pid) and is_binary(payload) do
    GenServer.cast(pid, {:send_text, payload})
  end

  @spec close(pid()) :: :ok
  def close(pid) when is_pid(pid) do
    GenServer.cast(pid, :close)
  end

  @impl true
  def init({url, owner, opts}) do
    with {:ok, connection} <- connect(url, opts),
         :ok <- set_active(connection.transport, connection.socket) do
      state = %{
        owner: owner,
        socket: connection.socket,
        transport: connection.transport,
        buffer: "",
        fragmented_text: nil,
        disconnected?: false
      }

      send_owner(owner, {:cerberus_bidi_connected, self()})

      case consume_frames(%{state | buffer: connection.buffer}) do
        {:ok, next_state} ->
          {:ok, next_state}

        {:disconnect, reason, next_state} ->
          {:stop, reason, maybe_mark_disconnected(next_state, reason)}
      end
    end
  end

  @impl true
  def handle_cast({:send_text, payload}, state) do
    frame = encode_frame(0x1, payload)

    case socket_send(state.transport, state.socket, frame) do
      :ok ->
        {:noreply, state}

      {:error, reason} ->
        next_state = maybe_mark_disconnected(state, reason)
        {:stop, reason, next_state}
    end
  end

  def handle_cast(:close, state) do
    _ = socket_send(state.transport, state.socket, encode_frame(0x8, ""))
    next_state = maybe_mark_disconnected(state, :closed_by_client)
    {:stop, :normal, next_state}
  end

  @impl true
  def handle_info({:tcp, socket, payload}, %{transport: :tcp, socket: socket} = state) when is_binary(payload) do
    with {:ok, next_state} <- consume_frames(%{state | buffer: state.buffer <> payload}),
         :ok <- set_active(:tcp, socket) do
      {:noreply, next_state}
    else
      {:disconnect, reason, next_state} ->
        {:stop, reason, maybe_mark_disconnected(next_state, reason)}

      {:error, reason} ->
        next_state = maybe_mark_disconnected(state, reason)
        {:stop, reason, next_state}
    end
  end

  def handle_info({:ssl, socket, payload}, %{transport: :ssl, socket: socket} = state) when is_binary(payload) do
    with {:ok, next_state} <- consume_frames(%{state | buffer: state.buffer <> payload}),
         :ok <- set_active(:ssl, socket) do
      {:noreply, next_state}
    else
      {:disconnect, reason, next_state} ->
        {:stop, reason, maybe_mark_disconnected(next_state, reason)}

      {:error, reason} ->
        next_state = maybe_mark_disconnected(state, reason)
        {:stop, reason, next_state}
    end
  end

  def handle_info({:tcp_closed, socket}, %{transport: :tcp, socket: socket} = state) do
    next_state = maybe_mark_disconnected(state, :closed)
    {:stop, :normal, next_state}
  end

  def handle_info({:ssl_closed, socket}, %{transport: :ssl, socket: socket} = state) do
    next_state = maybe_mark_disconnected(state, :closed)
    {:stop, :normal, next_state}
  end

  def handle_info({:tcp_error, socket, reason}, %{transport: :tcp, socket: socket} = state) do
    next_state = maybe_mark_disconnected(state, reason)
    {:stop, reason, next_state}
  end

  def handle_info({:ssl_error, socket, reason}, %{transport: :ssl, socket: socket} = state) do
    next_state = maybe_mark_disconnected(state, reason)
    {:stop, reason, next_state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    _ = close_socket(state.transport, state.socket)
    _ = maybe_mark_disconnected(state, reason)
    :ok
  end

  defp connect(url, opts) do
    with {:ok, uri} <- parse_ws_uri(url),
         {:ok, transport, socket} <- open_socket(uri, opts),
         :ok <- socket_send(transport, socket, build_handshake_request(uri, opts)),
         {:ok, response, buffer} <- recv_http_response(transport, socket, "", handshake_timeout(opts)),
         :ok <- validate_handshake_response(response) do
      {:ok, %{transport: transport, socket: socket, buffer: buffer}}
    end
  end

  defp parse_ws_uri(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host, port: port} = uri
      when scheme in ["ws", "wss"] and is_binary(host) and byte_size(host) > 0 and is_integer(port) ->
        path = if uri.path in [nil, ""], do: "/", else: uri.path
        {:ok, %{uri | path: path}}

      _ ->
        {:error, {:invalid_websocket_url, url}}
    end
  end

  defp open_socket(%URI{scheme: "ws", host: host, port: port}, opts) do
    connect_timeout = Keyword.get(opts, :socket_connect_timeout, @connect_timeout_ms)

    case :gen_tcp.connect(
           String.to_charlist(host),
           port,
           [:binary, {:active, false}, {:packet, :raw}],
           connect_timeout
         ) do
      {:ok, socket} -> {:ok, :tcp, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  defp open_socket(%URI{scheme: "wss", host: host, port: port}, opts) do
    connect_timeout = Keyword.get(opts, :socket_connect_timeout, @connect_timeout_ms)

    ssl_options =
      Keyword.get(opts, :ssl_options, [:binary, {:active, false}, {:packet, :raw}, {:verify, :verify_none}])

    case :ssl.connect(String.to_charlist(host), port, ssl_options, connect_timeout) do
      {:ok, socket} -> {:ok, :ssl, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_handshake_request(uri, opts) do
    path = if is_binary(uri.query), do: uri.path <> "?" <> uri.query, else: uri.path
    key = 16 |> :crypto.strong_rand_bytes() |> Base.encode64()

    headers =
      [
        {"Host", websocket_host_header(uri)},
        {"Connection", "Upgrade"},
        {"Upgrade", "websocket"},
        {"Sec-WebSocket-Version", "13"},
        {"Sec-WebSocket-Key", key}
      ] ++ Keyword.get(opts, :extra_headers, [])

    request_line = "GET #{path} HTTP/1.1"
    encoded_headers = Enum.map(headers, fn {field, value} -> "#{field}: #{value}" end)
    Enum.join([request_line | encoded_headers], "\r\n") <> "\r\n\r\n"
  end

  defp websocket_host_header(%URI{scheme: scheme, host: host, port: port}) do
    if default_port?(scheme, port), do: host, else: "#{host}:#{port}"
  end

  defp default_port?("ws", 80), do: true
  defp default_port?("wss", 443), do: true
  defp default_port?(_, _), do: false

  defp handshake_timeout(opts) do
    Keyword.get(opts, :socket_recv_timeout, @handshake_timeout_ms)
  end

  defp recv_http_response(transport, socket, buffer, timeout) do
    if String.contains?(buffer, "\r\n\r\n") do
      [headers, body] = String.split(buffer, "\r\n\r\n", parts: 2)
      {:ok, headers, body}
    else
      case socket_recv(transport, socket, timeout) do
        {:ok, data} -> recv_http_response(transport, socket, buffer <> data, timeout)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp validate_handshake_response(response) do
    status_line =
      response
      |> String.split("\r\n", parts: 2)
      |> hd()

    case Regex.run(~r/^HTTP\/1\.[01] (\d{3}) (.*)$/, status_line) do
      [_, "101", _message] ->
        :ok

      [_, code, message] ->
        {:error, %WebSockex.RequestError{code: String.to_integer(code), message: message}}

      _ ->
        {:error, {:invalid_handshake_response, status_line}}
    end
  end

  defp consume_frames(state) do
    case decode_frame(state.buffer) do
      {:more, buffer} ->
        {:ok, %{state | buffer: buffer}}

      {:ok, frame, rest} ->
        case handle_frame(frame, %{state | buffer: rest}) do
          {:ok, next_state} ->
            consume_frames(next_state)

          {:disconnect, reason, next_state} ->
            {:disconnect, reason, %{next_state | buffer: rest}}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp decode_frame(buffer) when byte_size(buffer) < 2, do: {:more, buffer}

  defp decode_frame(<<first, second, rest::binary>> = buffer) do
    fin = (first &&& 0x80) != 0
    opcode = first &&& 0x0F
    masked? = (second &&& 0x80) != 0
    payload_len_flag = second &&& 0x7F

    with {:ok, payload_len, rest} <- decode_payload_length(payload_len_flag, rest),
         {:ok, mask_key, rest} <- decode_mask(masked?, rest),
         true <- byte_size(rest) >= payload_len do
      <<payload::binary-size(payload_len), tail::binary>> = rest
      payload = if masked?, do: xor_payload(payload, mask_key), else: payload
      {:ok, %{fin: fin, opcode: opcode, payload: payload}, tail}
    else
      false ->
        {:more, buffer}

      {:more, _reason} ->
        {:more, buffer}
    end
  end

  defp decode_payload_length(length, rest) when length <= 125, do: {:ok, length, rest}

  defp decode_payload_length(126, <<length::16, rest::binary>>), do: {:ok, length, rest}
  defp decode_payload_length(126, _rest), do: {:more, :payload_length}

  defp decode_payload_length(127, <<length::64, rest::binary>>), do: {:ok, length, rest}
  defp decode_payload_length(127, _rest), do: {:more, :payload_length}

  defp decode_mask(true, <<mask_key::binary-size(4), rest::binary>>), do: {:ok, mask_key, rest}
  defp decode_mask(true, _rest), do: {:more, :mask}
  defp decode_mask(false, rest), do: {:ok, nil, rest}

  defp handle_frame(%{opcode: 0x1, fin: true, payload: payload}, state) do
    send_owner(state.owner, {:cerberus_bidi_frame, self(), payload})
    {:ok, %{state | fragmented_text: nil}}
  end

  defp handle_frame(%{opcode: 0x1, fin: false, payload: payload}, state) do
    {:ok, %{state | fragmented_text: payload}}
  end

  defp handle_frame(%{opcode: 0x0, fin: fin, payload: payload}, %{fragmented_text: fragment} = state)
       when is_binary(fragment) do
    text = fragment <> payload

    if fin do
      send_owner(state.owner, {:cerberus_bidi_frame, self(), text})
      {:ok, %{state | fragmented_text: nil}}
    else
      {:ok, %{state | fragmented_text: text}}
    end
  end

  defp handle_frame(%{opcode: 0x8, payload: payload}, state) do
    _ = socket_send(state.transport, state.socket, encode_frame(0x8, payload))
    {:disconnect, {:remote_close, decode_close_payload(payload)}, state}
  end

  defp handle_frame(%{opcode: 0x9, payload: payload}, state) do
    case socket_send(state.transport, state.socket, encode_frame(0xA, payload)) do
      :ok -> {:ok, state}
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_frame(_frame, state), do: {:ok, state}

  defp decode_close_payload(<<code::16, reason::binary>>), do: {code, reason}
  defp decode_close_payload(_payload), do: :closed

  defp encode_frame(opcode, payload) when is_integer(opcode) and is_binary(payload) do
    fin_opcode = 0x80 ||| opcode
    mask_key = :crypto.strong_rand_bytes(4)
    payload_size = byte_size(payload)

    {length_header, length_bytes} =
      cond do
        payload_size <= 125 ->
          {0x80 ||| payload_size, <<>>}

        payload_size <= 0xFFFF ->
          {0x80 ||| 126, <<payload_size::16>>}

        true ->
          {0x80 ||| 127, <<payload_size::64>>}
      end

    masked_payload = xor_payload(payload, mask_key)
    <<fin_opcode, length_header>> <> length_bytes <> mask_key <> masked_payload
  end

  defp xor_payload(payload, mask_key), do: xor_payload(payload, mask_key, 0, <<>>)

  defp xor_payload(<<>>, _mask_key, _index, acc), do: acc

  defp xor_payload(<<byte, rest::binary>>, mask_key, index, acc) do
    mask_byte = :binary.at(mask_key, rem(index, 4))
    xor_payload(rest, mask_key, index + 1, <<acc::binary, bxor(byte, mask_byte)>>)
  end

  defp socket_send(:tcp, socket, data), do: :gen_tcp.send(socket, data)
  defp socket_send(:ssl, socket, data), do: :ssl.send(socket, data)

  defp socket_recv(:tcp, socket, timeout), do: :gen_tcp.recv(socket, 0, timeout)
  defp socket_recv(:ssl, socket, timeout), do: :ssl.recv(socket, 0, timeout)

  defp set_active(:tcp, socket), do: :inet.setopts(socket, active: :once)
  defp set_active(:ssl, socket), do: :ssl.setopts(socket, active: :once)

  defp close_socket(_transport, nil), do: :ok
  defp close_socket(:tcp, socket), do: :gen_tcp.close(socket)
  defp close_socket(:ssl, socket), do: :ssl.close(socket)

  defp maybe_mark_disconnected(%{disconnected?: true} = state, _reason), do: state

  defp maybe_mark_disconnected(state, reason) do
    send_owner(state.owner, {:cerberus_bidi_disconnected, self(), reason})
    %{state | disconnected?: true}
  end

  defp send_owner(owner, event) when is_pid(owner) and is_tuple(event) do
    send(owner, event)
    :ok
  end
end
