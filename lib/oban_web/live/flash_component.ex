defmodule ObanWeb.FlashComponent do
  use ObanWeb.Web, :live_component

  def render(assigns) do
    ~L"""
    <div class="rounded-md bg-green-50 p-4 <%= if hidden?(@flash) do %>hidden<% end %>">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
          </svg>
        </div>

        <div class="ml-3">
          <p class="text-sm leading-5 font-medium text-green-800">
            <%= live_flash(@flash, :info) %>
          </p>
        </div>

        <div class="ml-auto pl-3">
          <div class="-mx-1.5 -my-1.5">
            <button phx-click="close" phx-target="<%= @myself %>" class="inline-flex rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:bg-green-100 transition ease-in-out duration-150">
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def hidden?(flash) do
    flash
    |> live_flash(:info)
    |> is_nil()
  end

  def handle_event("close", _params, socket) do
    {:noreply, clear_flash(socket)}
  end
end
