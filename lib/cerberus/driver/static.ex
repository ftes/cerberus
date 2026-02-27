defmodule Cerberus.Driver.Static do
  @moduledoc "Static driver adapter backed by a real Phoenix endpoint via ConnTest."

  @behaviour Cerberus.Driver

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Html
  alias Cerberus.Locator
  alias Cerberus.Query
  alias Cerberus.Session

  @type state :: %{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          html: String.t(),
          path: String.t() | nil
        }

  @impl true
  def new_session(opts \\ []) do
    endpoint = Conn.endpoint!(opts)

    %Session{
      driver: :static,
      driver_state: %{endpoint: endpoint, conn: nil, html: "", path: nil},
      meta: Map.new(opts)
    }
  end

  @impl true
  def visit(%Session{} = session, path, _opts) do
    state = state!(session)
    conn = Conn.ensure_conn(state.conn)
    conn = Conn.follow_get(state.endpoint, conn, path)
    html = conn.resp_body || ""
    current_path = Conn.current_path(conn, path)

    update_session(session, %{state | conn: conn, html: html, path: current_path}, :visit, %{
      path: current_path
    })
  end

  @impl true
  def click(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)

    case Html.find_link(state.html, expected, opts) do
      {:ok, link} when is_binary(link.href) ->
        updated = visit(session, link.href, [])
        updated_state = state!(updated)

        observed = %{
          action: :link,
          path: updated_state.path,
          clicked: link.text,
          texts: Html.texts(updated_state.html, :any)
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      :error ->
        case Html.find_button(state.html, expected, opts) do
          {:ok, button} ->
            observed = %{action: :button, clicked: button.text, path: state.path}
            {:error, session, observed, "static driver does not support dynamic button clicks"}

          :error ->
            observed = %{action: :click, path: state.path, texts: Html.texts(state.html, :any)}
            {:error, session, observed, "no clickable element matched locator"}
        end
    end
  end

  @impl true
  def assert_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(state.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: state.path,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched != [] do
      {:ok, update_last_result(session, :assert_has, observed), observed}
    else
      {:error, session, observed, "expected text not found"}
    end
  end

  @impl true
  def refute_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = state!(session)
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(state.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: state.path,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:ok, update_last_result(session, :refute_has, observed), observed}
    else
      {:error, session, observed, "unexpected matching text found"}
    end
  end

  defp state!(%Session{driver_state: %{} = state}), do: state
  defp state!(_), do: raise(ArgumentError, "static driver state is not initialized")

  defp update_session(%Session{} = session, state, op, observed) do
    %Session{
      session
      | driver_state: state,
        current_path: state.path,
        last_result: %{op: op, observed: observed}
    }
  end

  defp update_last_result(%Session{} = session, op, observed) do
    %Session{session | last_result: %{op: op, observed: observed}}
  end
end
