defmodule Oban.Web.DashboardLive do
  use Oban.Web, :live_view

  alias Oban.Job
  alias Oban.Web.Plugins.Stats
  alias Oban.Web.{Query, Telemetry}
  alias Oban.Web.{BulkActionComponent, DetailComponent, HeaderComponent, ListingComponent}
  alias Oban.Web.{NotificationComponent, RefreshComponent, SearchComponent, SidebarComponent}

  @flash_timing 5_000
  @default_limit 20
  @default_state "executing"

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    %{"oban" => oban, "refresh" => refresh, "transport" => transport} = session
    %{"user" => user, "access" => access, "csp_nonces" => csp_nonces} = session

    conf = await_config(oban)

    :ok = Stats.activate(oban)

    socket =
      assign(socket,
        access: access,
        conf: conf,
        csp_nonces: csp_nonces,
        params: %{},
        detailed: nil,
        jobs: [],
        node_stats: Stats.for_nodes(conf.name),
        queue_stats: Stats.for_queues(conf.name),
        state_stats: Stats.for_states(conf.name),
        refresh: refresh,
        selected: MapSet.new(),
        timer: nil,
        transport: transport,
        user: user
      )

    {:ok, init_schedule_refresh(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <meta name="live-transport" content="<%= @transport %>" />

    <main class="p-4">
      <%= live_component @socket, NotificationComponent, id: :flash, flash: @flash %>

      <header class="flex justify-between">
        <svg viewBox="0 0 127 48" class="h-12 text-gray-600 dark:text-gray-300">
          <title>Oban</title>
          <defs>
            <radialGradient cx="50%" cy="50%" fx="50%" fy="50%" r="54.834%" id="a">
              <stop stop-color="#4FD1C5" offset="0%"/>
              <stop stop-color="#285E61" offset="100%"/>
            </radialGradient>
          </defs>
          <g fill="currentColor" fill-rule="nonzero">
            <path d="M37.501 42.549a1.91 1.91 0 002.078-1.519c-.701.179-1.541.91-2.078 1.519zM8.811 41.19c-.51-.688-1.068-1.33-1.837-1.758.168 1.032.723 1.675 1.838 1.758zM23.437 1.226c-4.26-.905-6.857 1.36-10.388 1.919-1.453 1.54-3.565 2.205-5.036 3.676-.838.84-1.158 2.092-2.397 2.477.01.56-.52.952-.32 1.44.56-.16.494-.947 1.199-.96.136.103.315.167.32.4-.23.572-.794 1.102-1.518.72-.142.623-.884.992-1.359 1.518-1.356 1.502-3.04 6.106-1.2 7.914-.21.295.052 1.063-.16 1.358-.511-.451-.753.364-1.198.159.179-.69.562-1.72.08-2.397-.521.592-.665 2.073-.16 2.797-.49 2.761-.715 5.966.8 7.753.292.06.444-.197.639 0 .043.704.243 1.25.4 1.839-.799 1.745.994 4.83 2.317 5.915.889.728 1.959 1.773 2.717.48.565.66 1.255 1.195 1.838 1.838-.345.293-.783.493-.718 1.198 1.751 2.629 5.142 4.496 9.03 4.237-.1.48-.918.224-1.2.32.807.842 2.588 1.14 4.316 1.359 2.54.321 5.491.093 7.353-.8-.49-.017-1.029.015-1.039-.479 1.599.04 4.048.3 5.993-.56 1.556-.688 2.446-2.1 3.596-2.878-.133-.532-.398-.934-.798-1.199.725-.478 1.478-1.34 2.158-1.598.118.493.538.687 1.198.64 1.94-1.523 4.098-2.83 4.396-5.995-.062-.258-.385-.255-.4-.56.45-.482.56-1.303.878-1.918.32-.079.242.238.56.16 1.078-1.229 1.947-3.796 1.998-6.154.029-1.328.087-3.325-.56-4.317.015.549-.043 1.022-.56 1.039-.361-.839.309-1.084.4-1.599.779-4.376-2.3-6.585-2.956-9.992-.381-.23-.591-.631-1.12-.718.16.96.829 1.41 1.04 2.318-.655-.07-.701.47-1.118.639-.385-.735-.85-1.389-1.28-2.077.074-.193.322-.213.56-.24.307-.965-.246-1.785-.72-2.638-.895-1.612-3.278-3.772-5.114-2.877-.58-.565-1.485-.807-2.158-1.278.038-.284.358-.282.32-.64-1.435-1.754-4.33-2.134-7.352-2.079-.354.312-.887.445-.959 1.039h-1.518c.07-.546-.38-.917-.8-1.199zm.4-.16c.745.245 1.713.455 2.397 0-.514-.367-1.915-.495-2.397 0zM21.518.108c6.978-.62 12 1.52 16.223 4.235 3.78 2.43 6.344 5.92 8.232 9.832 2.22 4.602 2.77 12.1.878 17.264-3.56 9.721-12.48 17.522-25.253 16.465-7.607-.628-13.465-5.152-17.102-9.99C2.089 34.712.263 30.238.02 25.205-.21 20.382 1.493 14.83 3.217 12.016c1.557-2.538 4.42-5.846 7.273-7.753C13.423 2.305 17.052.503 21.518.108zm-6.952 3.437c.023.446-.415.776-.8.56.053-.4.36-.549.8-.56zm17.9.718c.034-.178.424-.062.48 0-.056.288-.374.113-.48 0zm-9.91 38.366c.415.07.88.13 1.28 0 .067-.695-1.376-.774-1.28 0zm-9.11-3.437c.175.35.692.723 1.12.56-.053-.515-.703-.892-1.12-.56zm24.615-3.357c.292.125.68-.253.64-.718-.472-.02-.632.273-.64.718zm-29.09-1.198c.22-.435-.11-.937-.56-.96-.178.393.196.85.56.96zm33.406-7.034c.233-.29.337-1.078.158-1.52-.811-.033-.771 1.404-.158 1.52zm-36.922-1.84c.697.034.634-1.448 0-1.438-.26.363-.12 1.012 0 1.438zm31.806-14.545c.11-.253-.198-.682-.638-.64.017.408.23.622.638.64zm-25.253-1.12c.445-.008.738-.168.72-.64-.465-.042-.845.348-.72.64zm.16 3.437c-2.391 2.698-4.273 6.503-3.836 11.75.735 8.83 7.612 15.097 17.022 14.467 8.548-.573 15.052-7.57 14.465-17.025-.298-4.794-2.66-8.154-5.194-10.55C32.133 9.82 27.672 7.86 22.796 8.26c-4.78.393-8.263 2.608-10.628 5.275zm17.98-8.872c-.084.393-.18.778-.24 1.2-.684.102-1.617-.473-1.997.078.265.922 1.691.652 2.078.08.435.1.793.275 1.2.4.92 1.637 3.246 1.869 5.034 2.639.433-.1.705-.362 1.118-.48.822.485 1.422 1.19 1.998 1.918-.69 1.075-.123 2.63.4 4.077.263.725.965 1.013 1.038 1.438.122.692-.39 1.469.32 1.919.287.046.387-.094.56-.16.043-.417-.153-.594-.16-.96.02-.407.543-.309.72-.559-.045-.375-.352-.665-.16-1.04.943.015.343.693.32 1.28-.018.399.257.892.238 1.199-.071 1.308-.575 2.986-.398 4.236.165 1.184 1.012 2.022.958 3.197.155.458.724.502.96.878-.163.637-.065 1.535-.32 2.079-.476-.132-.77-.02-1.2.08-.731 1.691-1.758 2.402-1.998 4.237-.08.62-.495 1.58-.478 2.158.01.393.485.747.478 1.118-.013.934-1.368 1.552-1.598 2.239-.281-.252-.723-.342-1.118-.48-1.493.825-3.341 1.295-4.396 2.558-.613-.285-1.493-.118-1.598.558.365.437.943-.131 1.36-.16.183.164.161.532.318.72.472-.06.976-.481 1.2.08-.092.364-.517.389-.8.56-.312.019-.415-.171-.638-.24-.504.269-1.442.647-1.998.16-2.578-.125-4.405.569-6.395 1.359-.4.213-.553.671-.718 1.12-.616.175-1.433-.104-2.238 0-.093-.414-.135-.879-.32-1.2-1.536-.764-3.763-1.949-6.394-1.919-.322.004-.588.185-.878.16-.373-.031-.667-.408-1.038-.48-.575-.108-1.943.11-1.52-.718.25-.488.786.2 1.12.08.186-.16.115-.578.318-.72-.938-1.565-2.79-2.218-4.234-3.277-.474.06-.837.23-1.2.4a22.51 22.51 0 01-1.358-2.238c.2-.385.473-.7.64-1.118-.275-2.067-.394-4.424-1.759-5.596-.025-.375-.171-.628-.24-.96-.294-.211-.803-.208-1.198-.32-.371-1.47-.075-2.553 1.039-2.876.28-1.785 1.403-2.83 1.358-4.715.608-.215 1.478-1.632.48-2-.372.161-.36.706-.64.96-.707-.142-.425-1.082-.159-1.519.115-.123.409-.07.639-.08.328-.258.423-.75.64-1.118 1.481-.287 1.961-2.44 2.556-3.757.262-.578.93-1.122.16-1.918.758-.805 1.94-2.297 3.198-1.2 2.713-.444 5.33-1.352 6.792-3.277a3.676 3.676 0 011.038-.08c.097.25.345.348.4.64-.325.182-.891.12-1.198.32.165.925 1.615.363 1.758-.16 1.597.267 2.813.173 4.076-.4.987.59 1.538-.668 1.997-.8.681-.195 1.153.437 2.078.4zm1.28-.08c-.168.035-.211-.055-.32-.08.009-.227.34-.153.32.08zm-18.06.72c-.07.117-.12.252-.32.238-.025-.21.11-.261.32-.238zM36.783 6.66c-.207.149-.507-.145-.64-.32.155-.356.716-.053.64.32zm-23.895-.16c-.047.307-.428.594-.72.4-.048-.4.436-.583.72-.4zm23.895.88c.396.084.848.35.638.799-.452.025-.59-.262-.798-.48-.058-.217.158-.16.16-.319zM9.77 9.06c-.093.431-.478.84-.878.718-.222-.453.366-1.01.878-.718zm-1.758.318c.105.028.126.142.24.16-.072.368-.367.712-.718.56-.019-.417.278-.52.478-.72zm32.367 1.76c-.273.128-.622-.26-.72-.56.207-.6 1.012.177.72.56zm1.918 2.717c.358.046.527.656.238.88-.243-.157-.401-.399-.398-.8.092.013.142-.019.16-.08zM5.535 33.517c.21-.023.262.112.24.32-.211.025-.263-.11-.24-.32zm36.202 1.518c.023.397-.163.584-.56.56.004-.348.272-.748.56-.56zm-2.478 3.279c-.113.365-.295.663-.718.718-.037-.07-.07-.142-.16-.16.038-.442.582-1.102.878-.558zM11.608 40.39c-.405.339-1.077.027-1.038-.558.445-.207.883.217 1.038.558zm24.375.72c-.057.43-.743.74-.958.32.106-.27.698-.713.958-.32z" fill="url(#a)"/><path d="M67 32.12c4.704 0 8.184-4.08 8.184-8.616 0-4.272-3.264-8.664-8.136-8.664-4.704 0-8.208 4.104-8.208 8.64 0 4.368 3.288 8.64 8.16 8.64zm.024-2.424c-3.336 0-5.448-3-5.448-6.216 0-3.072 2.016-6.192 5.448-6.192 3.264 0 5.4 2.952 5.4 6.192 0 3.048-1.968 6.216-5.4 6.216zM86.104 32c2.88 0 5.256-1.656 5.256-4.392 0-2.16-1.224-3.768-3.168-4.344 1.56-.696 2.448-2.304 2.448-3.96 0-2.136-1.488-4.344-3.888-4.344h-8.784V32h8.136zm-.504-9.696h-4.944v-5.016h5.088c1.272 0 2.208 1.056 2.208 2.52 0 1.44-1.032 2.496-2.352 2.496zm.504 7.368h-5.448v-5.208h5.616c1.344 0 2.328 1.248 2.328 2.64 0 1.392-1.08 2.568-2.496 2.568zM94.912 32l1.776-4.632h6.576l1.8 4.632h2.832l-6.72-17.04h-2.352L92.056 32h2.856zm7.824-6.624h-5.568l2.832-7.32 2.736 7.32zm9.96 6.624V20l9.648 12h2.232V14.984h-2.712v12.264L112.12 14.96h-2.112V32h2.688z" />
          </g>
        </svg>

        <%= live_component @socket, RefreshComponent, id: :refresh, refresh: @refresh %>
      </header>

      <div class="w-full flex flex-col my-6 md:flex-row">
        <div id="sidebar" class="mr-0 mb-3 md:mr-3 md:mb-0">
          <%= live_component @socket,
              SidebarComponent,
              id: :sidebar,
              access: @access,
              params: @params,
              node_stats: @node_stats,
              queue_stats: @queue_stats,
              state_stats: @state_stats %>
        </div>

        <div class="flex-1 bg-white dark:bg-gray-900 rounded-md shadow-lg overflow-hidden">
          <%= if @detailed do %>
            <%= live_component @socket, DetailComponent, id: :detail, access: @access, job: @detailed %>
          <% else %>
            <div class="flex justify-between items-center border-b border-gray-200 dark:border-gray-700 px-3 py-3">
              <%= live_component @socket, HeaderComponent, id: :header, params: @params, jobs: @jobs, stats: @state_stats, selected: @selected %>
              <%= live_component @socket, SearchComponent, id: :search, params: @params %>
            </div>

            <%= live_component @socket, BulkActionComponent, id: :bulk_action, access: @access, jobs: @jobs, selected: @selected %>
            <%= live_component @socket, ListingComponent, id: :listing, jobs: @jobs, params: @params, selected: @selected %>
          <% end %>
        </div>
      </div>

      <footer class="flex flex-col px-3 pb-6 text-sm justify-center items-center md:flex-row">
        <span class="text-gray-600 dark:text-gray-400 tabular mr-0 mb-1 md:mr-3 md:mb-0">Oban v<%= Application.spec(:oban, :vsn) %></span>
        <span class="text-gray-600 dark:text-gray-400 tabular mr-0 mb-1 md:mr-3 md:mb-0">Oban.Web v<%= Application.spec(:oban_web, :vsn) %></span>
        <span class="text-gray-600 dark:text-gray-400 tabular mr-0 mb-3 md:mr-3 md:mb-0">Oban.Pro v<%= Application.spec(:oban_pro, :vsn) %></span>

        <span class="text-gray-800 dark:text-gray-200 mr-1">
          <svg fill="currentColor" viewBox="0 0 20 20" class="h-5 w-5"><path fill-rule="evenodd" d="M18 3.315a.251.251 0 00-.073-.177l-1.065-1.065a.25.25 0 00-.353 0l-1.772 1.773a7.766 7.766 0 00-10.89 10.89L2.072 16.51a.251.251 0 000 .352l1.066 1.066a.25.25 0 00.352 0l1.773-1.772a7.766 7.766 0 0010.89-10.891l1.773-1.773A.252.252 0 0018 3.315zM5.474 10c0-1.21.471-2.345 1.326-3.2A4.496 4.496 0 0110 5.474c.867 0 1.697.243 2.413.695l-6.244 6.244A4.495 4.495 0 015.474 10zm9.052 0c0 1.209-.471 2.345-1.326 3.2a4.496 4.496 0 01-3.2 1.326 4.497 4.497 0 01-2.413-.695l6.244-6.244c.452.716.695 1.546.695 2.413z" /></svg>
        </span>

        <span class="text-gray-800 dark:text-gray-200 font-semibold">Made by Soren</span>
      </footer>
    </main>
    """
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => job_id}, _uri, socket) do
    {:noreply, assign(socket, detailed: %Job{id: job_id})}
  end

  def handle_params(params, _uri, socket) do
    normalize = fn
      {"limit", limit} -> {:limit, String.to_integer(limit)}
      {key, val} -> {String.to_existing_atom(key), val}
    end

    params =
      params
      |> Map.take(["limit", "node", "queue", "state", "terms"])
      |> Map.new(normalize)
      |> Map.put_new(:state, @default_state)
      |> Map.put_new(:limit, @default_limit)

    jobs = Query.get_jobs(socket.assigns.conf, params)

    {:noreply, assign(socket, detailed: nil, jobs: jobs, params: params)}
  end

  @impl Phoenix.LiveView
  def terminate(_reason, %{assigns: %{timer: timer}}) do
    if is_reference(timer), do: Process.cancel_timer(timer)

    :ok
  end

  def terminate(_reason, _socket), do: :ok

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    jobs = Query.get_jobs(socket.assigns.conf, socket.assigns.params)

    selected =
      jobs
      |> MapSet.new(& &1.id)
      |> MapSet.intersection(socket.assigns.selected)

    socket =
      assign(socket,
        detailed: refresh_job(socket.assigns.conf, socket.assigns.detailed),
        jobs: jobs,
        node_stats: Stats.for_nodes(socket.assigns.conf.name),
        queue_stats: Stats.for_queues(socket.assigns.conf.name),
        state_stats: Stats.for_states(socket.assigns.conf.name),
        selected: selected
      )

    {:noreply, schedule_refresh(socket)}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  # Queues

  def handle_info({:scale_queue, queue, limit}, socket) do
    Telemetry.action(:scale_queue, socket, [queue: queue, limit: limit], fn ->
      Oban.scale_queue(socket.assigns.conf.name, queue: queue, limit: limit)
    end)

    {:noreply, socket}
  end

  def handle_info({:pause_queue, queue}, socket) do
    Telemetry.action(:pause_queue, socket, [queue: queue], fn ->
      Oban.pause_queue(socket.assigns.conf.name, queue: queue)
    end)

    {:noreply, socket}
  end

  def handle_info({:resume_queue, queue}, socket) do
    Telemetry.action(:resume_queue, socket, [queue: queue], fn ->
      Oban.resume_queue(socket.assigns.conf.name, queue: queue)
    end)

    {:noreply, socket}
  end

  # Filtering

  def handle_info({:params, :limit, inc}, socket) when is_integer(inc) do
    params = Map.update!(socket.assigns.params, :limit, &to_string(&1 + inc))

    {:noreply, push_patch(socket, to: oban_path(socket, :home, params), replace: true)}
  end

  def handle_info({:params, key, value}, socket) do
    params =
      if is_nil(value) do
        Map.delete(socket.assigns.params, key)
      else
        Map.put(socket.assigns.params, key, value)
      end

    {:noreply, push_patch(socket, to: oban_path(socket, :home, params), replace: true)}
  end

  def handle_info({:update_refresh, refresh}, socket) do
    socket =
      socket
      |> assign(refresh: refresh)
      |> schedule_refresh()

    {:noreply, socket}
  end

  # Single Actions

  def handle_info({:cancel_job, job}, socket) do
    Telemetry.action(:cancel_jobs, socket, [job_ids: [job.id]], fn ->
      Oban.cancel_job(socket.assigns.conf.name, job.id)
    end)

    job = %{job | state: "cancelled", cancelled_at: DateTime.utc_now()}

    {:noreply, assign(socket, detailed: job)}
  end

  def handle_info({:delete_job, job}, socket) do
    Telemetry.action(:delete_jobs, socket, [job_ids: [job.id]], fn ->
      Query.delete_jobs(socket.assigns.conf, [job.id])
    end)

    {:noreply, assign(socket, detailed: nil)}
  end

  def handle_info({:retry_job, job}, socket) do
    Telemetry.action(:retry_jobs, socket, [job_ids: [job.id]], fn ->
      Query.deschedule_jobs(socket.assigns.conf, [job.id])
    end)

    job = %{job | state: "available", completed_at: nil, discarded_at: nil}

    {:noreply, assign(socket, detailed: job)}
  end

  # Selection

  def handle_info({:select_job, job}, socket) do
    {:noreply, assign(socket, selected: MapSet.put(socket.assigns.selected, job.id))}
  end

  def handle_info({:deselect_job, job}, socket) do
    {:noreply, assign(socket, selected: MapSet.delete(socket.assigns.selected, job.id))}
  end

  def handle_info(:select_all, socket) do
    {:noreply, assign(socket, selected: MapSet.new(socket.assigns.jobs, & &1.id))}
  end

  def handle_info(:deselect_all, socket) do
    {:noreply, assign(socket, selected: MapSet.new())}
  end

  def handle_info(:cancel_selected, socket) do
    job_ids = MapSet.to_list(socket.assigns.selected)

    Telemetry.action(:cancel_jobs, socket, [job_ids: job_ids], fn ->
      Query.cancel_jobs(socket.assigns.conf, job_ids)
    end)

    socket =
      socket
      |> hide_and_clear_selected()
      |> force_schedule_refresh()
      |> flash(:info, "Selected jobs canceled")

    {:noreply, socket}
  end

  def handle_info(:retry_selected, socket) do
    job_ids = MapSet.to_list(socket.assigns.selected)

    Telemetry.action(:retry_jobs, socket, [job_ids: job_ids], fn ->
      Query.deschedule_jobs(socket.assigns.conf, job_ids)
    end)

    socket =
      socket
      |> hide_and_clear_selected()
      |> force_schedule_refresh()
      |> flash(:info, "Selected jobs scheduled to run immediately")

    {:noreply, socket}
  end

  def handle_info(:delete_selected, socket) do
    job_ids = MapSet.to_list(socket.assigns.selected)

    Telemetry.action(:delete_jobs, socket, [job_ids: job_ids], fn ->
      Query.delete_jobs(socket.assigns.conf, job_ids)
    end)

    socket =
      socket
      |> hide_and_clear_selected()
      |> force_schedule_refresh()
      |> flash(:info, "Selected jobs deleted")

    {:noreply, socket}
  end

  ## Mount Helpers

  defp await_config(oban_name, timeout \\ 15_000) do
    Oban.config(oban_name)
  rescue
    exception in [RuntimeError] ->
      handler = fn _event, _timing, %{conf: conf}, pid ->
        send(pid, {:conf, conf})
      end

      :telemetry.attach("oban-await-config", [:oban, :supervisor, :init], handler, self())

      receive do
        {:conf, %{name: ^oban_name} = conf} ->
          conf
      after
        timeout -> reraise(exception, __STACKTRACE__)
      end
  after
    :telemetry.detach("oban-await-config")
  end

  ## Update Helpers

  defp refresh_job(conf, %Job{id: jid}) do
    case Query.fetch_job(conf, jid) do
      {:ok, job} -> job
      {:error, :not_found} -> nil
    end
  end

  defp refresh_job(_conf, _job), do: nil

  defp flash(socket, mode, message) do
    Process.send_after(self(), :clear_flash, @flash_timing)

    put_flash(socket, mode, message)
  end

  defp hide_and_clear_selected(socket) do
    %{jobs: jobs, selected: selected} = socket.assigns

    jobs = for job <- jobs, do: Map.put(job, :hidden?, MapSet.member?(selected, job.id))

    assign(socket, jobs: jobs, selected: MapSet.new())
  end

  ## Refresh Helpers

  defp init_schedule_refresh(socket) do
    if connected?(socket) do
      schedule_refresh(socket)
    else
      assign(socket, timer: nil)
    end
  end

  defp schedule_refresh(socket) do
    if is_reference(socket.assigns.timer), do: Process.cancel_timer(socket.assigns.timer)

    if socket.assigns.refresh > 0 do
      interval = :timer.seconds(socket.assigns.refresh) - 50

      assign(socket, timer: Process.send_after(self(), :refresh, interval))
    else
      assign(socket, timer: nil)
    end
  end

  defp force_schedule_refresh(socket, override \\ 1) do
    original = socket.assigns.refresh

    socket
    |> assign(refresh: override)
    |> schedule_refresh()
    |> assign(refresh: original)
  end
end
