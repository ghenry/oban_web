defmodule Oban.Web.SidebarComponent do
  use Oban.Web, :live_component

  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="sidebar" class="mr-0 mb-3 md:mr-3 md:mb-0">
      <%= if :nodes in @sections do %>
        <.section id="nodes" name="Nodes" headers={~w(Exec Limit)}>
          <%= for node <- nodes(@gossip) do %>
            <.node_row node={node} page={@page} params={@params} socket={@socket} />
          <% end %>
        </.section>
      <% end %>

      <%= if :states in @sections do %>
        <.section id="states" name="States" headers={~w(Count)}>
          <%= for state <- states(@counts) do %>
            <.state_row state={state} page={@page} params={@params} socket={@socket} />
          <% end %>
        </.section>
      <% end %>

      <%= if :queues in @sections do %>
        <.section id="queues" name="Queues" headers={~w(Mode Limit Exec Avail)}>
          <%= for queue <- queues(@gossip, @counts) do %>
            <.queue_row queue={queue} page={@page} params={@params} socket={@socket} />
          <% end %>
        </.section>
      <% end %>
    </div>
    """
  end

  defp section(assigns) do
    ~H"""
    <div id={@id} class="bg-white dark:bg-gray-900 w-fill mb-3 rounded-md shadow-lg overflow-hidden md:w-84">
      <header class="group flex justify-between items-center border-b border-gray-200 dark:border-gray-700 px-3 py-3">
        <span class="dark:text-gray-200 font-bold"><%= @name %></span>

        <div class="flex group-hover:hidden">
          <%= for header <- @headers do %>
            <div class="text-xs text-gray-500 uppercase text-right w-10">
              <%= header %>
            </div>
          <% end %>
        </div>

        <div class="hidden group-hover:block">
          <button class="block w-5 h-5 text-gray-400 dark:text-gray-600 hover:text-blue-500" title="Minimize or maximize" phx-click={toggle(@id)}>
            <svg id={"#{@id}-hide-icon"} class="block" fill="currentColor" viewBox="0 0 20 20"><path d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 000 2h6a1 1 0 100-2H7z" clip-rule="evenodd" fill-rule="evenodd"></path></svg>
            <svg id={"#{@id}-show-icon"} class="hidden" fill="currentColor" viewBox="0 0 20 20"><path d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clip-rule="evenodd" fill-rule="evenodd"></path></svg>
          </button>
        </div>
      </header>

      <div id={"#{@id}-rows"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp node_row(assigns) do
    active_class =
      if assigns.params[:node] == assigns.node.name,
        do: "border-blue-500",
        else: "border-transparent"

    ~H"""
    <%= live_patch(
        to: filter_link(@socket, @page, :node, @node.name, @params),
        replace: true,
        id: "node-#{sanitize_name(@node.name)}",
        rel: "filter",
        class: "flex justify-between py-3 border-l-4 hover:bg-gray-50 dark:hover:bg-blue-300 dark:hover:bg-opacity-25 #{active_class}") do %>
      <span class="pl-2 text-sm dark:text-gray-300 text-left font-semibold truncate">
        <%= String.downcase(@node.name) %>
      </span>
      <div class="flex-none">
        <span class="pr-3 text-sm text-gray-400 text-right tabular"><%= integer_to_estimate(@node.count) %></span>
        <span class="pr-3 text-sm text-gray-400 text-right w-10 tabular"><%= integer_to_estimate(@node.limit) %></span>
      </div>
    <% end %>
    """
  end

  defp state_row(assigns) do
    active_class =
      if assigns.params[:state] == assigns.state.name,
        do: "border-blue-500",
        else: "border-transparent"

    ~H"""
    <%= live_patch(
        to: filter_link(@socket, @page, :state, @state.name, @params),
        replace: true,
        id: "state-#{@state.name}",
        rel: "filter",
        class: "flex justify-between py-3 border-l-4 hover:bg-gray-50 dark:hover:bg-blue-300 dark:hover:bg-opacity-25 #{active_class}") do %>
      <span class="pl-2 text-sm dark:text-gray-300 text-left font-semibold truncate"><%= @state.name %></span>
      <span class="pr-3 text-sm text-gray-400 text-right tabular"><%= integer_to_estimate(@state.count) %></span>
    <% end %>
    """
  end

  defp queue_row(assigns) do
    active_class =
      if assigns.params[:queue] == assigns.queue.name,
        do: "border-blue-500",
        else: "border-transparent"

    ~H"""
    <%= live_patch(
        to: filter_link(@socket, @page, :queue, @queue.name, @params),
        replace: true,
        id: "queue-#{@queue.name}",
        rel: "filter",
        class: "flex justify-between py-3 border-l-4 hover:bg-gray-50 dark:hover:bg-blue-300 dark:hover:bg-opacity-25 #{active_class}") do %>
      <span class="pl-2 text-sm dark:text-gray-300 text-left font-semibold truncate"><%= @queue.name %></span>

      <div class="pr-3 flex items-center flex-none">
        <div class="flex items-center text-right">
          <%= if @queue.rate_limited? do %>
            <svg class="text-gray-400 w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"></path></svg>
          <% end %>

          <%= if @queue.global? do %>
            <svg class="text-gray-400 w-4 h-4 ml-1"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path></svg>
          <% end %>

          <div class="text-gray-400 text-sm w-10 tabular"><%= integer_to_estimate(@queue.limit) %></div>
        </div>
        <div class="text-gray-400 text-sm text-right w-10 tabular"><%= integer_to_estimate(@queue.execu) %></div>
        <div class="text-gray-400 text-sm text-right w-10 tabular"><%= integer_to_estimate(@queue.avail) %></div>
      </div>
    <% end %>
    """
  end

  defp filter_link(socket, page, key, value, params) do
    params =
      if params[key] == value do
        Map.delete(params, key)
      else
        Map.put(params, key, value)
      end

    oban_path(socket, page, params)
  end

  # Effects

  defp toggle(prefix) do
    JS.toggle(to: "##{prefix}-hide-icon")
    |> JS.toggle(to: "##{prefix}-show-icon")
    |> JS.toggle(to: "##{prefix}-rows")
  end

  # Helpers

  defp nodes(gossip) do
    gossip
    |> Enum.reduce(%{}, &aggregate_nodes/2)
    |> Map.values()
    |> Enum.sort_by(& &1.name)
  end

  defp aggregate_nodes(gossip, acc) do
    full_name = node_name(gossip)
    empty_fun = fn -> %{name: full_name, count: 0, limit: 0} end

    acc
    |> Map.put_new_lazy(full_name, empty_fun)
    |> update_in([full_name, :count], &(&1 + length(gossip["running"])))
    |> update_in([full_name, :limit], &(&1 + (gossip["limit"] || gossip["local_limit"])))
  end

  @ordered_states ~w(executing available scheduled retryable cancelled discarded completed)

  defp states(counts) do
    for state <- @ordered_states do
      count = Enum.reduce(counts, 0, &(&1[state] + &2))

      %{name: state, count: count}
    end
  end

  defp queues(gossip, counts) do
    avail_counts = Map.new(counts, fn %{"name" => key, "available" => val} -> {key, val} end)
    execu_counts = Map.new(counts, fn %{"name" => key, "executing" => val} -> {key, val} end)

    # TODO: Change this to reflect global state
    total_limits =
      Enum.reduce(gossip, %{}, fn payload, acc ->
        limit = payload_limit(payload)

        Map.update(acc, payload["queue"], limit, &(&1 + limit))
      end)

    pause_states =
      Enum.reduce(gossip, %{}, fn %{"paused" => paused, "queue" => queue}, acc ->
        Map.update(acc, queue, paused, &(&1 or paused))
      end)

    [avail_counts, execu_counts, total_limits]
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(fn queue ->
      %{
        name: queue,
        avail: Map.get(avail_counts, queue, 0),
        execu: Map.get(execu_counts, queue, 0),
        limit: Map.get(total_limits, queue, 0),
        paused?: Map.get(pause_states, queue, true),
        global?: Enum.any?(gossip, &(&1["queue"] == queue and is_integer(&1["global_limit"]))),
        rate_limited?: Enum.any?(gossip, &(&1["queue"] == queue and is_map(&1["rate_limit"])))
      }
    end)
  end

  defp payload_limit(%{"global_limit" => limit}) when is_integer(limit), do: limit
  defp payload_limit(%{"local_limit" => limit}) when is_integer(limit), do: limit
  defp payload_limit(%{"limit" => limit}), do: limit
  defp payload_limit(_payload), do: 0

  defp sanitize_name(name) do
    name
    |> String.downcase()
    |> String.replace("/", "_")
  end
end
