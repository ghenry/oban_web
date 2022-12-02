defmodule Oban.Web.SidebarComponentTest do
  use Oban.Web.Case, async: true

  alias Oban.Web.Components.Refresh

  test "rendering the refresh selector with children" do
    html = render_component(Refresh, refresh: 1, myself: "id")

    assert has_fragment?(html, "#refresh-selector")
    assert has_fragment?(html, "li[role='option']")
  end
end
