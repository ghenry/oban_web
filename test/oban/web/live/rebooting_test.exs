defmodule Oban.Web.Live.RebootingTest do
  use Oban.Web.DataCase, async: true

  import Phoenix.LiveViewTest

  alias Oban.Web.Plugins.Stats

  test "waiting for oban config while mounting during a restart" do
    task =
      Task.async(fn ->
        Process.sleep(25)

        {:ok, _} = Oban.start_link(name: Oban, repo: Repo, plugins: [Stats])

        receive do
          :mounted -> :ok
        after
          1_000 -> :error
        end
      end)

    assert {:ok, _, _} = live(build_conn(), "/oban")

    send(task.pid, :mounted)

    assert :ok = Task.await(task)
  end
end
