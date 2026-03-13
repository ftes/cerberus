defmodule Cerberus.Fixtures.PhoenixTestPlaywright.PerformanceLive do
  @moduledoc false

  use Phoenix.LiveView

  @candidate_results [
    %{id: "wizard-archive", name: "Wizard Archive", score: "score 91", region: "North"},
    %{id: "wizard-prime", name: "Wizard Prime", score: "score 98", region: "Central"},
    %{id: "wizard-second", name: "Wizard Second", score: "score 93", region: "South"},
    %{id: "hazel-wiz", name: "Hazel Wiz", score: "score 89", region: "West"},
    %{id: "night-wizard", name: "Night Wizard", score: "score 92", region: "East"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       candidate_modal_open?: false,
       candidate_query: "",
       candidate_results: [],
       selected_candidate: nil,
       rows_loaded?: false,
       review_modal_open?: false,
       reviewed_slot: nil,
       step: "start"
     )}
  end

  def handle_params(params, _uri, socket) do
    selected_candidate =
      case Map.get(params, "candidate") do
        nil -> socket.assigns.selected_candidate
        candidate_id -> candidate_by_id(candidate_id)
      end

    {:noreply,
     assign(socket,
       selected_candidate: selected_candidate,
       step: Map.get(params, "step", "start")
     )}
  end

  def render(assigns) do
    assigns =
      assign(
        assigns,
        :candidate_name,
        if(assigns.selected_candidate, do: assigns.selected_candidate.name)
      )

    ~H"""
    <section id="performance-live-root">
      <h1>Performance LiveView</h1>

      <div class="benchmark-actions">
        <button type="button" phx-click="open-candidate-modal">Open candidate search</button>
        <button type="button" phx-click="load-results">Load heavy results</button>
        <button type="button" phx-click="navigate-done">Continue workflow</button>
      </div>

      <div data-testid="selected-candidate">
        Selected candidate: {@candidate_name || "none"}
      </div>

      <div data-testid="flow-step">Step: {@step}</div>

      <div
        :if={@candidate_modal_open?}
        id="candidate-modal"
        role="dialog"
        aria-label="Candidate search"
        data-testid="candidate-modal"
      >
        <h2>Candidate search</h2>

        <form id="candidate-search-form" phx-change="candidate-search">
          <label for="candidate-search">Candidate search</label>
          <input id="candidate-search" name="candidate_search" value={@candidate_query} />
        </form>

        <div data-testid="candidate-results">
          <article
            :for={candidate <- @candidate_results}
            data-testid="candidate-option"
            data-candidate-id={candidate.id}
          >
            <header>
              <h3>{candidate.name}</h3>
              <span>{candidate.score}</span>
            </header>
            <p>Region: {candidate.region}</p>
            <div class="candidate-actions">
              <button type="button">Dismiss</button>
              <button type="button" phx-click="choose-candidate" phx-value-id={candidate.id}>Choose</button>
            </div>
          </article>
        </div>
      </div>

      <section :if={@rows_loaded?} id="result-grid" data-testid="result-grid">
        <article
          :for={index <- 1..160}
          data-card-kind="result"
          data-testid={"result-card-#{index}"}
          data-slot={index}
        >
          <header>
            <h3>{card_title(index, @selected_candidate)}</h3>
            <span class="result-badge">{card_status(index)}</span>
            <span class="result-slot">slot-{index}</span>
          </header>

          <div class="result-body">
            <p>Noise paragraph {index}</p>
            <p>Noise paragraph {index + 100}</p>

            <ul>
              <li>tag-alpha-{rem(index, 11)}</li>
              <li>tag-beta-{rem(index, 13)}</li>
              <li>{card_marker(index)}</li>
            </ul>

            <div class="result-actions">
              <button type="button">Ignore</button>
              <button type="button" phx-click="review-card" phx-value-slot={index}>Review</button>
            </div>
          </div>
        </article>
      </section>

      <div
        :if={@review_modal_open?}
        id="review-modal"
        role="dialog"
        aria-label="Review candidate"
        data-testid="review-modal"
      >
        <h2>Review candidate</h2>
        <p>{@candidate_name}</p>
        <p>slot-{@reviewed_slot}</p>
        <p>status-ready</p>

        <div class="review-actions">
          <button type="button">Close</button>
          <button type="button" phx-click="apply-filters">Apply filters</button>
        </div>
      </div>
    </section>
    """
  end

  def handle_event("open-candidate-modal", _, socket) do
    Process.send_after(self(), :show_candidate_modal, 60)
    {:noreply, socket}
  end

  def handle_event("candidate-search", %{"candidate_search" => query}, socket) do
    Process.send_after(self(), {:candidate_search_results, query}, 80)
    {:noreply, assign(socket, :candidate_query, query)}
  end

  def handle_event("choose-candidate", %{"id" => id}, socket) do
    Process.send_after(self(), {:choose_candidate, id}, 70)
    {:noreply, socket}
  end

  def handle_event("load-results", _, socket) do
    Process.send_after(self(), :load_results, 90)
    {:noreply, socket}
  end

  def handle_event("review-card", %{"slot" => slot}, socket) do
    {slot, ""} = Integer.parse(slot)
    Process.send_after(self(), {:open_review_modal, slot}, 75)
    {:noreply, socket}
  end

  def handle_event("apply-filters", _, socket) do
    Process.send_after(self(), :patch_filters, 70)
    {:noreply, socket}
  end

  def handle_event("navigate-done", _, socket) do
    Process.send_after(self(), :navigate_done, 90)
    {:noreply, socket}
  end

  def handle_info(:show_candidate_modal, socket) do
    {:noreply, assign(socket, :candidate_modal_open?, true)}
  end

  def handle_info({:candidate_search_results, query}, socket) do
    results =
      if String.trim(query) == "" do
        []
      else
        filter_candidates(query)
      end

    {:noreply, assign(socket, candidate_query: query, candidate_results: results)}
  end

  def handle_info({:choose_candidate, id}, socket) do
    candidate = candidate_by_id(id)

    {:noreply,
     assign(socket,
       selected_candidate: candidate,
       candidate_modal_open?: false,
       candidate_results: [],
       review_modal_open?: false,
       reviewed_slot: nil
     )}
  end

  def handle_info(:load_results, socket) do
    {:noreply, assign(socket, :rows_loaded?, true)}
  end

  def handle_info({:open_review_modal, slot}, socket) do
    {:noreply, assign(socket, review_modal_open?: true, reviewed_slot: slot)}
  end

  def handle_info(:patch_filters, socket) do
    candidate = socket.assigns.selected_candidate || candidate_by_id("wizard-prime")

    {:noreply,
     push_patch(socket,
       to: "/phoenix_test/playwright/live/performance?step=patched&candidate=#{URI.encode_www_form(candidate.id)}"
     )}
  end

  def handle_info(:navigate_done, socket) do
    candidate = socket.assigns.selected_candidate || candidate_by_id("wizard-prime")

    {:noreply,
     push_navigate(socket,
       to: "/phoenix_test/playwright/live/performance/done?candidate=#{URI.encode_www_form(candidate.id)}"
     )}
  end

  defp filter_candidates(query) do
    normalized_query = String.downcase(String.trim(query))

    Enum.filter(@candidate_results, fn candidate ->
      String.contains?(String.downcase(candidate.name), normalized_query)
    end)
  end

  defp candidate_by_id(id) do
    Enum.find(@candidate_results, &(&1.id == id))
  end

  defp card_title(120, %{name: name}), do: name
  defp card_title(90, %{name: name}), do: name
  defp card_title(60, %{name: name}), do: name
  defp card_title(index, %{name: name}), do: "Result #{index} for #{name}"
  defp card_title(index, _candidate), do: "Result #{index}"

  defp card_status(120), do: "status-ready"
  defp card_status(90), do: "status-ready"
  defp card_status(60), do: "status-pending"
  defp card_status(index), do: "status-#{rem(index, 5)}"

  defp card_marker(120), do: "priority-prime"
  defp card_marker(90), do: "priority-backup"
  defp card_marker(60), do: "priority-prime"
  defp card_marker(index), do: "priority-#{rem(index, 9)}"
end

defmodule Cerberus.Fixtures.PhoenixTestPlaywright.PerformanceDoneLive do
  @moduledoc false

  use Phoenix.LiveView

  def mount(params, _session, socket) do
    {:ok, assign(socket, :candidate, Map.get(params, "candidate", ""))}
  end

  def render(assigns) do
    ~H"""
    <section id="performance-live-done">
      <h1>Performance flow complete</h1>
      <p data-testid="done-candidate">Candidate carried forward: {@candidate}</p>
    </section>
    """
  end
end
