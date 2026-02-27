defmodule Cerberus.Driver.Live do
  @moduledoc "Live driver adapter backed by a real Phoenix endpoint via LiveViewTest."

  @behaviour Cerberus.Driver

  import Phoenix.LiveViewTest, only: [element: 3, render: 1, render_click: 1]

  alias Cerberus.Driver.Conn
  alias Cerberus.Driver.Html
  alias Cerberus.Locator
  alias Cerberus.Query
  alias Cerberus.Session

  @type state :: %{
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          mode: :static | :live,
          view: term() | nil,
          html: String.t(),
          path: String.t() | nil
        }

  @impl true
  def new_session(opts \\ []) do
    endpoint = Conn.endpoint!(opts)

    %Session{
      driver: :live,
      driver_state: %{
        endpoint: endpoint,
        conn: nil,
        mode: :static,
        view: nil,
        html: "",
        path: nil
      },
      meta: Map.new(opts)
    }
  end

  @impl true
  def visit(%Session{} = session, path, _opts) do
    state = state!(session)
    conn = Conn.ensure_conn(state.conn)
    conn = Conn.follow_get(state.endpoint, conn, path)
    current_path = Conn.current_path(conn, path)

    {mode, view, html} =
      case try_live(conn) do
        {:ok, view, html} ->
          {:live, view, html}

        :error ->
          {:static, nil, conn.resp_body || ""}
      end

    update_session(
      session,
      %{state | conn: conn, mode: mode, view: view, html: html, path: current_path},
      :visit,
      %{
        path: current_path,
        mode: mode
      }
    )
  end

  @impl true
  def click(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))

    case Html.find_link(state.html, expected, opts) do
      {:ok, link} when is_binary(link.href) ->
        updated = visit(session, link.href, [])
        updated_state = state!(updated)

        observed = %{
          action: :link,
          path: updated_state.path,
          mode: updated_state.mode,
          clicked: link.text,
          texts: Html.texts(updated_state.html, :any)
        }

        {:ok, update_last_result(updated, :click, observed), observed}

      :error ->
        case Html.find_button(state.html, expected, opts) do
          {:ok, button} when state.mode == :live and state.view != nil ->
            click_live_button(session, state, button)

          {:ok, button} ->
            observed = %{
              action: :button,
              clicked: button.text,
              path: state.path,
              mode: state.mode
            }

            {:error, session, observed, "live driver can only click buttons on live routes"}

          :error ->
            observed = %{
              action: :click,
              path: state.path,
              mode: state.mode,
              texts: Html.texts(state.html, :any)
            }

            {:error, session, observed, "no clickable element matched locator"}
        end
    end
  end

  @impl true
  def assert_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(state.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: state.path,
      mode: state.mode,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched != [] do
      {:ok, update_session(session, state, :assert_has, observed), observed}
    else
      {:error, session, observed, "expected text not found"}
    end
  end

  @impl true
  def refute_has(%Session{} = session, %Locator{kind: :text, value: expected}, opts) do
    state = with_latest_html(state!(session))
    visible = Keyword.get(opts, :visible, true)
    texts = Html.texts(state.html, visible)
    matched = Enum.filter(texts, &Query.match_text?(&1, expected, opts))

    observed = %{
      path: state.path,
      mode: state.mode,
      visible: visible,
      texts: texts,
      matched: matched,
      expected: expected
    }

    if matched == [] do
      {:ok, update_session(session, state, :refute_has, observed), observed}
    else
      {:error, session, observed, "unexpected matching text found"}
    end
  end

  defp click_live_button(session, state, button) do
    result =
      state.view
      |> element("button", button.text)
      |> render_click()

    case result do
      rendered when is_binary(rendered) ->
        updated_state = %{state | html: rendered}

        observed = %{
          action: :button,
          clicked: button.text,
          path: state.path,
          mode: :live,
          texts: Html.texts(rendered, :any)
        }

        {:ok, update_session(session, updated_state, :click, observed), observed}

      {:error, {:live_redirect, %{to: to}}} ->
        redirected_result(session, button, to)

      {:error, {:redirect, %{to: to}}} ->
        redirected_result(session, button, to)

      {:error, {:live_patch, %{to: to}}} ->
        rendered = render(state.view)
        updated_state = %{state | html: rendered, path: to}

        observed = %{
          action: :button,
          clicked: button.text,
          path: to,
          mode: :live,
          texts: Html.texts(rendered, :any)
        }

        {:ok, update_session(session, updated_state, :click, observed), observed}

      other ->
        observed = %{
          action: :button,
          clicked: button.text,
          path: state.path,
          mode: state.mode,
          result: other
        }

        {:error, session, observed, "unexpected live click result"}
    end
  end

  defp redirected_result(session, button, to) do
    updated = visit(session, to, [])
    updated_state = state!(updated)

    observed = %{
      action: :button,
      clicked: button.text,
      path: updated_state.path,
      mode: updated_state.mode,
      texts: Html.texts(updated_state.html, :any)
    }

    {:ok, update_last_result(updated, :click, observed), observed}
  end

  defp try_live(conn) do
    case Phoenix.LiveViewTest.__live__(conn, nil, []) do
      {:ok, view, html} -> {:ok, view, html}
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp with_latest_html(%{mode: :live, view: view} = state) when not is_nil(view) do
    %{state | html: render(view)}
  end

  defp with_latest_html(state), do: state

  defp state!(%Session{driver_state: %{} = state}), do: state
  defp state!(_), do: raise(ArgumentError, "live driver state is not initialized")

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
