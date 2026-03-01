defmodule Cerberus.Driver.Browser.WSTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Browser.WS

  test "handshake host header includes non-default port" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, {:active, false}, {:packet, :raw}, {:reuseaddr, true}])
    {:ok, port} = :inet.port(listener)
    parent = self()

    task =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listener, 2_000)
        {:ok, request} = recv_until_headers(socket, "")
        send(parent, {:request, request})

        :ok =
          :gen_tcp.send(
            socket,
            "HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n"
          )

        Process.sleep(150)
        :ok = :gen_tcp.close(socket)
      end)

    url = "ws://127.0.0.1:#{port}/session/test"
    {:ok, pid} = WS.start_link(url, self(), extra_headers: [{"Sec-WebSocket-Protocol", "webDriverBidi"}])

    assert_receive {:request, request}, 1_000
    assert request =~ "Host: 127.0.0.1:#{port}\r\n"
    assert_receive {:cerberus_bidi_connected, ^pid}, 1_000
    assert_receive {:cerberus_bidi_disconnected, ^pid, _reason}, 1_000

    Task.await(task)
    :ok = :gen_tcp.close(listener)
  end

  test "forwards incoming text frames to owner" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, {:active, false}, {:packet, :raw}, {:reuseaddr, true}])
    {:ok, port} = :inet.port(listener)
    parent = self()

    task =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listener, 2_000)
        {:ok, _request} = recv_until_headers(socket, "")

        :ok =
          :gen_tcp.send(
            socket,
            "HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n"
          )

        :ok = :gen_tcp.send(socket, <<0x81, 5, "hello">>)
        Process.sleep(150)
        :ok = :gen_tcp.close(socket)
        send(parent, :server_done)
      end)

    url = "ws://127.0.0.1:#{port}/session/test"
    {:ok, pid} = WS.start_link(url, self(), extra_headers: [{"Sec-WebSocket-Protocol", "webDriverBidi"}])

    assert_receive {:cerberus_bidi_connected, ^pid}, 1_000
    assert_receive {:cerberus_bidi_frame, ^pid, "hello"}, 1_000
    assert_receive :server_done, 1_000
    assert_receive {:cerberus_bidi_disconnected, ^pid, _reason}, 1_000

    Task.await(task)
    :ok = :gen_tcp.close(listener)
  end

  test "treats remote close code 1000 as normal shutdown" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, {:active, false}, {:packet, :raw}, {:reuseaddr, true}])
    {:ok, port} = :inet.port(listener)
    parent = self()

    task =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listener, 2_000)
        {:ok, _request} = recv_until_headers(socket, "")

        :ok =
          :gen_tcp.send(
            socket,
            "HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n"
          )

        receive do
          :send_close -> :ok
        after
          2_000 -> flunk("timed out waiting to send close frame")
        end

        # Server close frame with status code 1000 (normal closure)
        :ok = :gen_tcp.send(socket, <<0x88, 0x02, 0x03, 0xE8>>)
        Process.sleep(150)
        :ok = :gen_tcp.close(socket)
        send(parent, :server_done)
      end)

    url = "ws://127.0.0.1:#{port}/session/test"
    {:ok, pid} = WS.start_link(url, self(), extra_headers: [{"Sec-WebSocket-Protocol", "webDriverBidi"}])
    ref = Process.monitor(pid)

    assert_receive {:cerberus_bidi_connected, ^pid}, 1_000
    send(task.pid, :send_close)
    assert_receive :server_done, 1_000
    assert_receive {:cerberus_bidi_disconnected, ^pid, {:remote_close, {1000, ""}}}, 1_000
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 1_000

    Task.await(task)
    :ok = :gen_tcp.close(listener)
  end

  defp recv_until_headers(socket, buffer) do
    if String.contains?(buffer, "\r\n\r\n") do
      {:ok, buffer}
    else
      case :gen_tcp.recv(socket, 0, 2_000) do
        {:ok, chunk} -> recv_until_headers(socket, buffer <> chunk)
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
