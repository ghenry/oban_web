defmodule Oban.Web.DetailComponentTest do
  use Oban.Web.DataCase

  import Phoenix.LiveViewTest

  alias Oban.Web.Jobs.DetailComponent, as: Component

  test "rendering job details" do
    job = %Oban.Job{id: 1, worker: "MyApp.Worker", args: %{}}

    html = render_component(Component, access: :read_only, id: job.id, job: job)

    assert html =~ job.worker
  end

  test "restricting action buttons based on access" do
    job = %Oban.Job{id: 1, worker: "MyApp.Worker", args: %{}, state: "retryable"}

    html = render_component(Component, access: :read_only, id: job.id, job: job)
    refute html =~ ~s(phx-click="cancel")

    html = render_component(Component, access: :all, id: job.id, job: job)
    assert html =~ ~s(phx-click="cancel")
  end

  test "restricting actions based on job state" do
    job = %Oban.Job{id: 1, worker: "MyApp.Worker", args: %{}, state: "executing"}

    html = render_component(Component, access: :all, id: job.id, job: job)

    assert html =~ ~s(phx-click="cancel")
    refute html =~ ~s(phx-click="delete")
  end
end
