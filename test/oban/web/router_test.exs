defmodule Oban.Web.RouterTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias Oban.Web.Router
  alias Plug.Conn

  defmodule Resolver do
    @behaviour Oban.Web.Resolver

    @impl true
    def resolve_user(conn) do
      conn.private.current_user
    end

    @impl true
    def resolve_access(user) do
      if user.admin? do
        :all
      else
        :read
      end
    end

    @impl true
    def resolve_refresh, do: 5
  end

  describe "__options__" do
    test "setting default options in the router module" do
      options = Router.__options__([])

      assert options[:as] == :oban_dashboard
      assert options[:layout] == {Oban.Web.LayoutView, "app.html"}
    end

    test "passing the transport through to the session" do
      assert %{"transport" => "longpoll"} = options_to_session(transport: "longpoll")
    end

    test "passing a resolver module through to the session" do
      conn =
        :get
        |> conn("/oban")
        |> Conn.put_private(:current_user, %{id: 1, admin?: false})

      session = options_to_session(conn, resolver: Resolver)

      assert %{"access" => :read, "refresh" => 5, "user" => %{id: 1}} = session
    end

    test "validating oban name values" do
      assert_raise ArgumentError, ~r/invalid :oban_name/, fn ->
        Router.__options__(oban_name: "MyApp.Oban")
      end
    end

    test "validating transport values" do
      assert_raise ArgumentError, ~r/invalid :transport/, fn ->
        Router.__options__(transport: "webpoll")
      end
    end

    test "validating resolve_user values" do
      assert_raise ArgumentError, ~r/invalid :resolver/, fn ->
        Router.__options__(resolver: nil)
      end
    end
  end

  defp options_to_session(opts) do
    :get
    |> conn("/oban")
    |> options_to_session(opts)
  end

  defp options_to_session(conn, opts) do
    {Router, :__session__, session_opts} =
      opts
      |> Router.__options__()
      |> Keyword.get(:session)

    apply(Router, :__session__, [conn | session_opts])
  end
end
