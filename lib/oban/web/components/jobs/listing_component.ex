defmodule Oban.Web.Jobs.ListingComponent do
  use Oban.Web, :live_component

  alias Oban.Web.Jobs.ListingRowComponent

  @inc_limit 20
  @max_limit 200
  @min_limit 20

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       jobs: assigns.jobs,
       selected: assigns.selected,
       show_less?: assigns.params.limit > @min_limit,
       show_more?: assigns.params.limit < @max_limit
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="listing">
      <div class="flex justify-between border-b border-gray-200 dark:border-gray-700 px-3 py-3">
        <span class="text-xs text-gray-400 pl-8 uppercase">Worker</span>

        <div class="flex justify-end">
          <span class="flex-none w-24 text-xs text-right text-gray-400 pl-3 uppercase">Queue</span>
          <span class="flex-none w-20 text-xs text-right text-gray-400 pl-3 uppercase">Atmpt</span>
          <span class="flex-none w-20 text-xs text-right text-gray-400 pl-3 mr-8 uppercase">Time</span>
        </div>
      </div>

      <%= if Enum.empty?(@jobs) do %>
        <div class="flex justify-center py-20">
          <span class="text-lg text-gray-500 dark:text-gray-400 ml-3">No jobs match the current set of filters.</span>
        </div>
      <% else %>
        <ul>
          <%= for job <- @jobs do %>
            <.live_component id={job.id} module={ListingRowComponent} job={job} selected={@selected} />
          <% end %>
        </ul>

        <div class="flex justify-center py-6">
          <button type="button"
            class="font-semibold text-sm mr-6 focus:outline-none #{activity_class(@show_less?)}"
            phx-target={@myself}
            phx-click="load_less">Show Less</button>

          <button type="button"
            class={"font-semibold text-sm focus:outline-none #{activity_class(@show_more?)}"}
            phx-target={@myself}
            phx-click="load_more">Show More</button>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("load_less", _params, socket) do
    if socket.assigns.show_less? do
      send(self(), {:params, :limit, -@inc_limit})
    end

    {:noreply, socket}
  end

  def handle_event("load_more", _params, socket) do
    if socket.assigns.show_more? do
      send(self(), {:params, :limit, @inc_limit})
    end

    {:noreply, socket}
  end

  defp activity_class(true) do
    """
    text-gray-700 dark:text-gray-300 cursor-pointer transition ease-in-out duration-200 border-b
    border-gray-200 dark:border-gray-800 hover:border-gray-400
    """
  end

  defp activity_class(_), do: "text-gray-400 dark:text-gray-600 cursor-not-allowed"
end
