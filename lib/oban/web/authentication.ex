defmodule Oban.Web.Authentication do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView

  alias Oban.Web.Telemetry

  def on_mount(:default, params, session, socket) do
    %{"oban" => oban, "resolver" => resolver, "user" => user} = session

    conf = if Oban.whereis(oban), do: Oban.config(oban), else: nil
    socket = assign(socket, conf: conf, user: user)

    Telemetry.action(:mount, socket, [params: params], fn ->
      case resolver.resolve_access(user) do
        {:forbidden, path} ->
          socket =
            socket
            |> put_flash(:error, "Access forbidden")
            |> redirect(to: path)

          {:halt, socket}

        _ ->
          {:cont, socket}
      end
    end)
  end
end
