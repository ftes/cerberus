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
       scenario: "churn",
       candidate_modal_open?: false,
       candidate_query: "",
       candidate_results: [],
       selected_candidate: nil,
       rows_loaded?: false,
       review_modal_open?: false,
       reviewed_slot: nil,
       assignment_modal_open?: false,
       selected_assignment: nil,
       step: "start",
       flow_events: [],
       flow_event_count: 0
     )}
  end

  def handle_params(params, uri, socket) do
    selected_candidate =
      case Map.get(params, "candidate") do
        nil -> socket.assigns.selected_candidate
        candidate_id -> candidate_by_id(candidate_id)
      end

    flow_path = current_flow_path(socket, uri)

    {:noreply,
     assign(socket,
       flow_path: flow_path,
       done_path: flow_path <> "/done",
       scenario: Map.get(params, "scenario", socket.assigns.scenario || "churn"),
       selected_candidate: selected_candidate,
       selected_assignment: assignment_by_id(Map.get(params, "assignment")) || socket.assigns.selected_assignment,
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
        <button
          :if={locator_stress_scenario?(@scenario)}
          type="button"
          phx-click="apply-filters"
        >
          Apply locator filters
        </button>
        <button type="button" phx-click="navigate-done">Continue workflow</button>
      </div>

      <div data-testid="benchmark-scenario">Scenario: {@scenario}</div>

      <div data-testid="selected-candidate">
        Selected candidate: {@candidate_name || "none"}
      </div>

      <div :if={@selected_assignment} data-testid="selected-assignment">
        Selected assignment: {@selected_assignment.name}
      </div>

      <div data-testid="flow-step">Step: {@step}</div>
      <div data-testid="flow-event-count">Flow events: {@flow_event_count}</div>
      <div data-testid="flow-proof">Flow proof: {Enum.join(@flow_events, ">")}</div>

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

          <div :if={locator_stress_scenario?(@scenario)} class="assignment-panel-stack">
            <section
              :for={panel <- card_assignment_panels(index)}
              data-panel-kind="assignment"
              data-panel-id={panel.id}
            >
              <header>
                <h4>{panel.name}</h4>
                <span>{panel.region}</span>
              </header>
              <p>{panel.lane}</p>
              <p>{panel.window}</p>
              <p>{panel.skill}</p>
              <p>{panel.batch}</p>
              <p :if={panel.duplicate_lure?}>duplicate-lure</p>

              <div class="panel-actions">
                <button type="button">Archive queue</button>

                <button
                  type="button"
                  phx-click="open-assignment-modal"
                  phx-value-slot={index}
                  phx-value-panel={panel.id}
                >
                  Inspect queue
                </button>
              </div>
            </section>
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

      <div
        :if={@assignment_modal_open?}
        id="assignment-modal"
        role="dialog"
        aria-label="Assignment queue"
        data-testid="assignment-modal"
      >
        <h2>Assignment queue</h2>

        <div data-testid="assignment-rows">
          <article
            :for={assignment <- assignment_queue_rows(@selected_candidate, @reviewed_slot)}
            data-testid="assignment-row"
            data-assignment-id={assignment.id}
          >
            <header>
              <h3>{assignment.name}</h3>
              <span>{assignment.state}</span>
            </header>
            <p>{assignment.region}</p>
            <p>{assignment.window}</p>
            <p>{assignment.skill}</p>
            <p>{assignment.owner}</p>
            <p :if={assignment.secondary_marker?}>secondary-marker</p>

            <div class="assignment-actions">
              <button type="button">Dismiss</button>

              <button type="button" phx-click="choose-assignment" phx-value-id={assignment.id}>
                Select
              </button>
            </div>
          </article>
        </div>
      </div>
    </section>
    """
  end

  def handle_event("open-candidate-modal", _, socket) do
    Process.send_after(self(), :show_candidate_modal, delay_ms(socket, 60))
    {:noreply, socket}
  end

  def handle_event("candidate-search", %{"candidate_search" => query}, socket) do
    Process.send_after(self(), {:candidate_search_results, query}, delay_ms(socket, 80))
    {:noreply, assign(socket, :candidate_query, query)}
  end

  def handle_event("choose-candidate", %{"id" => id}, socket) do
    Process.send_after(self(), {:choose_candidate, id}, delay_ms(socket, 70))
    {:noreply, socket}
  end

  def handle_event("load-results", _, socket) do
    Process.send_after(self(), :load_results, delay_ms(socket, 90))
    {:noreply, socket}
  end

  def handle_event("review-card", %{"slot" => slot}, socket) do
    {slot, ""} = Integer.parse(slot)
    Process.send_after(self(), {:open_review_modal, slot}, delay_ms(socket, 75))
    {:noreply, socket}
  end

  def handle_event("open-assignment-modal", %{"slot" => slot, "panel" => _panel}, socket) do
    {slot, ""} = Integer.parse(slot)
    Process.send_after(self(), {:open_assignment_modal, slot}, delay_ms(socket, 85))
    {:noreply, socket}
  end

  def handle_event("choose-assignment", %{"id" => id}, socket) do
    Process.send_after(self(), {:choose_assignment, id}, delay_ms(socket, 70))
    {:noreply, socket}
  end

  def handle_event("apply-filters", _, socket) do
    Process.send_after(self(), :patch_filters, delay_ms(socket, 70))
    {:noreply, socket}
  end

  def handle_event("navigate-done", _, socket) do
    Process.send_after(self(), :navigate_done, delay_ms(socket, 90))
    {:noreply, socket}
  end

  def handle_info(:show_candidate_modal, socket) do
    {:noreply,
     socket
     |> assign(:candidate_modal_open?, true)
     |> record_flow_event("candidate-modal-opened")}
  end

  def handle_info({:candidate_search_results, query}, socket) do
    results =
      if String.trim(query) == "" do
        []
      else
        filter_candidates(query)
      end

    {:noreply,
     socket
     |> assign(candidate_query: query, candidate_results: results)
     |> record_flow_event("candidate-results-loaded")}
  end

  def handle_info({:choose_candidate, id}, socket) do
    candidate = candidate_by_id(id)

    {:noreply,
     socket
     |> assign(
       selected_candidate: candidate,
       candidate_modal_open?: false,
       candidate_results: [],
       review_modal_open?: false,
       reviewed_slot: nil
     )
     |> record_flow_event("candidate-chosen")}
  end

  def handle_info(:load_results, socket) do
    {:noreply,
     socket
     |> assign(:rows_loaded?, true)
     |> record_flow_event("results-loaded")}
  end

  def handle_info({:open_review_modal, slot}, socket) do
    {:noreply,
     socket
     |> assign(review_modal_open?: true, reviewed_slot: slot)
     |> record_flow_event("review-opened")}
  end

  def handle_info({:open_assignment_modal, slot}, socket) do
    {:noreply,
     socket
     |> assign(assignment_modal_open?: true, reviewed_slot: slot)
     |> record_flow_event("assignment-modal-opened")}
  end

  def handle_info({:choose_assignment, id}, socket) do
    {:noreply,
     socket
     |> assign(
       selected_assignment: assignment_by_id(id),
       assignment_modal_open?: false
     )
     |> record_flow_event("assignment-chosen")}
  end

  def handle_info(:patch_filters, socket) do
    candidate = socket.assigns.selected_candidate || candidate_by_id("wizard-prime")
    assignment = socket.assigns.selected_assignment
    socket = record_flow_event(socket, "filters-patched")

    query =
      [
        {"step", "patched"},
        {"candidate", candidate.id},
        {"scenario", socket.assigns.scenario}
      ]
      |> maybe_put_query("assignment", assignment && assignment.id)
      |> URI.encode_query()

    {:noreply,
     push_patch(socket,
       to: "#{socket.assigns.flow_path}?#{query}"
     )}
  end

  def handle_info(:navigate_done, socket) do
    candidate = socket.assigns.selected_candidate || candidate_by_id("wizard-prime")
    assignment = socket.assigns.selected_assignment
    socket = record_flow_event(socket, "done-navigated")

    query =
      [
        {"candidate", candidate.id},
        {"proof", Enum.join(socket.assigns.flow_events, ">")},
        {"events", Integer.to_string(socket.assigns.flow_event_count)}
      ]
      |> maybe_put_query("assignment", assignment && assignment.id)
      |> URI.encode_query()

    {:noreply,
     push_navigate(socket,
       to: "#{socket.assigns.done_path}?#{query}"
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

  defp locator_stress_scenario?(scenario), do: scenario == "locator_stress"

  defp current_flow_path(socket, uri) do
    case uri do
      value when is_binary(value) ->
        case URI.parse(value) do
          %URI{path: path} when is_binary(path) and path != "" -> path
          _ -> socket.assigns[:flow_path] || "/phoenix_test/playwright/live/performance"
        end

      _ ->
        socket.assigns[:flow_path] || "/phoenix_test/playwright/live/performance"
    end
  end

  defp delay_ms(socket, normal_delay) when is_integer(normal_delay) and normal_delay >= 0 do
    if socket.assigns.scenario == "churn_no_delay", do: 0, else: normal_delay
  end

  defp assignment_by_id(nil), do: nil

  defp assignment_by_id(id) do
    Enum.find(assignment_queue_rows(candidate_by_id("wizard-prime"), 120), &(&1.id == id))
  end

  defp maybe_put_query(params, _key, nil), do: params
  defp maybe_put_query(params, key, value), do: params ++ [{key, value}]

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

  defp card_assignment_panels(120) do
    [
      %{
        id: "assignment-shadow",
        name: "Queue Cobalt",
        region: "region-central",
        lane: "lane-27",
        window: "window-3",
        skill: "skill-runes",
        batch: "batch-orchid",
        duplicate_lure?: true
      },
      %{
        id: "assignment-target",
        name: "Queue Cobalt",
        region: "region-central",
        lane: "lane-27",
        window: "window-3",
        skill: "skill-runes",
        batch: "batch-orchid",
        duplicate_lure?: false
      },
      %{
        id: "assignment-backup",
        name: "Queue Amber",
        region: "region-central",
        lane: "lane-27",
        window: "window-3",
        skill: "skill-runes",
        batch: "batch-orchid",
        duplicate_lure?: false
      }
    ]
  end

  defp card_assignment_panels(index) do
    for panel_index <- 1..3 do
      %{
        id: "assignment-#{index}-#{panel_index}",
        name: "Queue #{index}-#{panel_index}",
        region: "region-#{rem(index, 9)}",
        lane: "lane-#{rem(index + panel_index, 31)}",
        window: "window-#{rem(index + panel_index, 5)}",
        skill: "skill-#{rem(index + panel_index, 7)}",
        batch: "batch-#{rem(index * panel_index, 17)}",
        duplicate_lure?: false
      }
    end
  end

  defp assignment_queue_rows(candidate, 120) do
    owner = "owner-#{candidate_id(candidate)}"

    [
      %{
        id: "queue-shadow",
        name: "Queue Cobalt",
        state: "state-ready",
        region: "region-central",
        window: "window-3",
        skill: "skill-runes",
        owner: owner,
        secondary_marker?: true
      },
      %{
        id: "queue-cobalt",
        name: "Queue Cobalt",
        state: "state-ready",
        region: "region-central",
        window: "window-3",
        skill: "skill-runes",
        owner: owner,
        secondary_marker?: false
      },
      %{
        id: "queue-amber",
        name: "Queue Amber",
        state: "state-ready",
        region: "region-central",
        window: "window-3",
        skill: "skill-runes",
        owner: owner,
        secondary_marker?: false
      }
      | assignment_queue_rows(candidate, 90)
    ]
  end

  defp assignment_queue_rows(candidate, slot) do
    owner = "owner-#{candidate_id(candidate)}"

    for offset <- 1..36 do
      %{
        id: "queue-#{slot}-#{offset}",
        name: "Queue #{slot}-#{offset}",
        state: "state-#{rem(slot + offset, 5)}",
        region: "region-#{rem(slot + offset, 9)}",
        window: "window-#{rem(slot + offset, 5)}",
        skill: "skill-#{rem(slot + offset, 7)}",
        owner: owner,
        secondary_marker?: false
      }
    end
  end

  defp candidate_id(%{id: id}), do: id
  defp candidate_id(nil), do: "wizard-prime"

  defp record_flow_event(socket, event) when is_binary(event) do
    socket
    |> update(:flow_events, &(&1 ++ [event]))
    |> update(:flow_event_count, &(&1 + 1))
  end
end

defmodule Cerberus.Fixtures.PhoenixTestPlaywright.PerformanceDoneLive do
  @moduledoc false

  use Phoenix.LiveView

  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       candidate: Map.get(params, "candidate", ""),
       assignment: Map.get(params, "assignment", ""),
       proof: Map.get(params, "proof", ""),
       events: Map.get(params, "events", "")
     )}
  end

  def render(assigns) do
    ~H"""
    <section id="performance-live-done">
      <h1>Performance flow complete</h1>
      <p data-testid="done-candidate">Candidate carried forward: {@candidate}</p>
      <p :if={@assignment != ""} data-testid="done-assignment">
        Assignment carried forward: {@assignment}
      </p>
      <p data-testid="done-proof">Flow proof: {@proof}</p>
      <p data-testid="done-event-count">Flow events: {@events}</p>
    </section>
    """
  end
end
