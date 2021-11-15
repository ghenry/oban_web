defmodule Oban.Web.Components.FormComponent do
  @moduledoc """
  Shared form components.
  """

  use Phoenix.Component

  @doc """
  A numerical input with increment and decrement buttons.
  """
  def number_input(assigns) do
    ~H"""
    <div>
      <%= if @label do %>
        <label for={@name} class={"block font-medium text-sm mb-2 #{if @disabled, do: "text-gray-600 dark:text-gray-400", else: "text-gray-800 dark:text-gray-200"}"}>
          <%= @label %>
        </label>
      <% end %>

      <div class="flex">
        <input
          autocomplete="off"
          class="w-1/2 flex-1 min-w-0 block font-mono text-sm shadow-sm border-gray-300 dark:border-gray-500 disabled:border-gray-400 dark:disabled:border-gray-700 bg-gray-100 dark:bg-gray-800 disabled:bg-gray-200 dark:disabled:bg-gray-900 rounded-l-md focus:ring-blue-400 focus:border-blue-400"
          disabled={@disabled}
          id={@name}
          inputmode="numeric"
          name={@name}
          pattern="[1-9][0-9]*"
          placeholder="Off"
          type="text"
          value={@value} />

        <div class="w-9">
          <button
            rel="inc"
            class={"block -ml-px px-3 py-1 bg-gray-300 dark:bg-gray-500 disabled:bg-gray-400 dark:disabled:bg-gray-600 rounded-tr-md hover:bg-gray-200 dark:hover:bg-gray-600 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 cursor-pointer #{if @disabled, do: "cursor-not-allowed pointer-events-none"}"}
            disabled={@disabled}
            type="button"
            phx-click="increment"
            phx-target={@myself}
            phx-value-field={@name}>
            <svg class="w-3 h-3 text-gray-600 dark:text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path></svg>
          </button>

          <button
            rel="dec"
            class={"block -ml-px px-3 py-1 bg-gray-300 dark:bg-gray-500 disabled:bg-gray-400 dark:disabled:bg-gray-600 rounded-br-md hover:bg-gray-200 dark:hover:bg-gray-600 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 cursor-pointer #{if @disabled, do: "cursor-not-allowed pointer-events-none"}"}
            disabled={@disabled}
            tabindex="-1"
            type="button"
            phx-click="decrement"
            phx-target={@myself}
            phx-value-field={@name}>
            <svg class="w-3 h-3 text-gray-600 dark:text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          </button>
        </div>
      </div>
    </div>
    """
  end
end
