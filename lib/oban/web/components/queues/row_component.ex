defmodule Oban.Web.Queues.RowComponent do
  use Oban.Web, :live_component

  alias Oban.Web.Timing

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, expanded?: false)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~L"""
    <tr id="<%= queue_id(@queue) %>" class="bg-white dark:bg-gray-900 hover:bg-blue-50 dark:hover:bg-blue-300 dark:hover:bg-opacity-25">
      <td class="p-3 flex">
        <button rel="expand" class="block pr-2 text-gray-400 hover:text-blue-500" phx-click="toggle_expanded" phx-target="<%= @myself %>">
          <%= if @expanded? do %>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <% else %>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
          <% end %>
        </button>

        <span rel="name"><%= @queue %></span>
      </td>

      <td rel="nodes" class="py-3 pl-3 text-right tabular"><%= nodes_count(@gossip) %></td>
      <td rel="executing" class="py-3 pl-3 text-right tabular"><%= executing_count(@gossip) %></td>
      <td rel="available" class="py-3 pl-3 text-right tabular"><%= available_count(@counts) %></td>
      <td rel="local" class="py-3 pl-3 text-right tabular"><%= local_limit(@gossip) %></td>
      <td rel="global" class="py-3 pl-3 text-right tabular"><%= global_limit(@gossip) %></td>
      <td rel="rate" class="py-3 pl-3 text-right tabular"><%= rate_limit(@gossip) %></td>
      <td rel="started" class="py-3 pl-3 text-right tabular"><%= started_at(@gossip) %></td>

      <td class="py-3 pr-3 flex justify-end">
        <%= if can?(:pause_queues, @access) do %>
          <button rel="play_pause" class="block pr-2 <%= pause_color(@gossip) %> hover:text-blue-500" title="Pause or resume queue" phx-click="play_pause" phx-target="<%= @myself %>" phx-throttle="1000">
            <%= if any_paused?(@gossip) do %>
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <% else %>
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <% end %>
          </button>
        <% end %>

        <%= if can?(:scale_queues, @access) do %>
          <button class="block text-gray-400 hover:text-blue-500">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path></svg>
          </button>
        <% end %>
      </td>
    </tr>

    <%= if @expanded? do %>
      <%= for entry <- @gossip do %>
        <tr id="<%= queue_id(@queue, entry["node"]) %>" class="text-gray-400 bg-gray-100 dark:bg-black dark:bg-opacity-25">
          <td colspan="2"class="py-3 text-right"><%= node_name(entry["name"], entry["node"]) %></td>
          <td class="py-3 text-right tabular"><%= length(entry["running"]) %></td>
          <td class="py-3 text-right tabular"><%= available_count(@counts) %></td>
          <td class="py-3 text-right tabular"><%= Map.get(entry, "local_limit", "-") %></td>
          <td class="py-3 text-right tabular"><%= Map.get(entry, "global_limit", "-") %></td>
          <td class="py-3 text-right tabular"><%= rate_limit([entry]) %></td>
          <td class="py-3 text-right tabular"><%= started_at([entry]) %></td>
          <td class="py-3 pr-10 flex justify-end">
            <%= if can?(:pause_queues, @access) do %>
              <button rel="play_pause" class="block <%= if entry["paused"] do %>text-red-500<% else %>text-gray-500<% end %> hover:text-blue-500"
                title="Pause or resume queue"
                phx-click="play_pause"
                phx-target="<%= @myself %>"
                phx-throttle="1000"
                phx-name="<%= entry["name"] %>"
                phx-node="<%= entry["node"] %>">
                <%= if entry["paused"] do %>
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <% else %>
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <% end %>
              </button>
            <% end %>
          </td>
        </tr>
      <% end %>
    <% end %>
    """
  end

  # Handlers

  @impl Phoenix.LiveComponent
  def handle_event("play_pause", %{"name" => name, "node" => node}, socket) do
    if can?(:pause_queues, socket.assigns.access) do
      gossip = Enum.find(socket.assigns.gossip, &(&1["name"] == name and &1["node"] == node))
      action = if gossip["paused"], do: :resume_queue, else: :pause_queue

      send(self(), {action, socket.assigns.queue, name, node})
    end

    {:noreply, socket}
  end

  def handle_event("play_pause", _params, socket) do
    if can?(:pause_queues, socket.assigns.access) do
      action = if any_paused?(socket.assigns.gossip), do: :resume_queue, else: :pause_queue

      send(self(), {action, socket.assigns.queue})
    end

    {:noreply, socket}
  end

  def handle_event("toggle_expanded", _params, socket) do
    {:noreply, assign(socket, expanded?: not socket.assigns.expanded?)}
  end

  # Helpers

  defp queue_id(queue), do: ["queue-", queue]
  defp queue_id(queue, node), do: ["queue-", queue, "-node-", String.replace(node, ".", "_")]

  defp pause_color(gossip) do
    cond do
      Enum.all?(gossip, & &1["paused"]) -> "text-red-500"
      Enum.any?(gossip, & &1["paused"]) -> "text-yellow-400"
      true -> "text-gray-400"
    end
  end

  defp nodes_count(gossip), do: length(gossip)

  defp executing_count(gossip) do
    for %{"running" => running} <- gossip, reduce: 0, do: (acc -> acc + length(running))
  end

  defp available_count(counts) do
    counts
    |> Map.get("available", 0)
    |> integer_to_estimate()
  end

  defp local_limit(gossip) do
    gossip
    |> Enum.map(& &1["local_limit"])
    |> Enum.min_max()
    |> case do
      {min, min} -> min
      {min, max} -> "#{min}..#{max}"
    end
  end

  defp global_limit(gossip) do
    total = for %{"local_limit" => limit} <- gossip, reduce: 0, do: (acc -> acc + limit)

    Enum.find_value(gossip, total, & &1["global_limit"])
  end

  defp rate_limit(gossip) do
    case for %{"rate_limit" => rate} <- gossip, do: rate do
      [] ->
        "-"

      [rate | _] = rates ->
        %{"allowed" => allowed, "period" => period, "window_time" => time} = rate

        curr_time = Time.truncate(Time.utc_now(), :second)

        prev_total = for %{"prev_count" => cnt} <- rates, reduce: 0, do: (acc -> acc + cnt)
        curr_total = for %{"curr_count" => cnt} <- rates, reduce: 0, do: (acc -> acc + cnt)

        ellapsed =
          time
          |> Time.from_iso8601!()
          |> Time.diff(curr_time, :second)
          |> abs()

        remaining = prev_total * div(period - ellapsed, period) + curr_total

        period_in_words = Timing.to_words(period, relative: false)

        "#{remaining}/#{allowed} per #{period_in_words}"
    end
  end

  defp started_at(gossip) do
    gossip
    |> Enum.map(& &1["started_at"])
    |> Enum.map(&started_at_to_diff/1)
    |> Enum.max()
    |> Timing.to_words()
  end

  defp started_at_to_diff(started_at) do
    {:ok, date_time, _} = DateTime.from_iso8601(started_at)

    DateTime.diff(date_time, DateTime.utc_now())
  end

  defp any_paused?(gossip), do: Enum.any?(gossip, & &1["paused"])
end
