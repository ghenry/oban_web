defmodule Oban.Web.Queues.DetailComponentTest do
  use Oban.Web.DataCase, async: true

  import Phoenix.LiveViewTest

  alias Oban.Config
  alias Oban.Queue.BasicEngine
  alias Oban.Web.Queues.DetailComponent, as: Component

  @queue "alpha"

  test "restricting actions based on access" do
    html = render_component(Component, assigns(access: :read_only), router: Router)

    assert has_fragment?(html, "#local_limit[disabled]")
    assert has_fragment?(html, "#global_limit[disabled]")
    assert has_fragment?(html, "#rate_limit_allowed[disabled]")

    html = render_component(Component, assigns(access: :all), router: Router)

    refute has_fragment?(html, "#local_limit[disabled]")
    refute has_fragment?(html, "#global_limit[disabled]")
    refute has_fragment?(html, "#rate_limit_allowed[disabled]")
  end

  test "listing all queue instances" do
    gossip = [
      build_gossip(queue: @queue, node: "web.1", name: "Oban"),
      build_gossip(queue: @queue, node: "web.1", name: "Private"),
      build_gossip(queue: @queue, node: "web.2", name: "Oban")
    ]

    html = render_component(Component, assigns(gossip: gossip), router: Router)

    assert html =~ "web.1/oban"
    assert html =~ "web.1/private"
    assert html =~ "web.2/oban"
  end

  test "disabling advanced features when SmartEngine isn't available" do
    conf = Config.new(engine: BasicEngine, repo: Repo)
    html = render_component(Component, assigns(conf: conf), router: Router)

    assert has_fragment?(html, "#global-limit-fields [rel=requires-pro]")
    assert has_fragment?(html, "#rate-limit-fields [rel=requires-pro]")

    # Pro isn't available, we check whether the engine isn't the BasicEngine instead
    conf = %{conf | engine: FakeEngine}
    html = render_component(Component, assigns(conf: conf), router: Router)

    refute has_fragment?(html, "#global-limit-fields [rel=requires-pro]")
    refute has_fragment?(html, "#rate-limit-fields [rel=requires-pro]")
  end

  defp assigns(opts) do
    [access: :all, conf: Config.new(repo: Repo), id: :detail, queue: @queue]
    |> Keyword.put(:counts, [counts()])
    |> Keyword.put(:gossip, [build_gossip(queue: @queue)])
    |> Keyword.merge(opts)
  end

  defp counts do
    %{
      "name" => "alpha",
      "available" => 0,
      "cancelled" => 0,
      "completed" => 0,
      "discarded" => 0,
      "executing" => 0,
      "retryable" => 0,
      "scheduled" => 0
    }
  end

  defp has_fragment?(html, selector) do
    fragment =
      html
      |> Floki.parse_fragment!()
      |> Floki.find(selector)

    fragment != []
  end
end
