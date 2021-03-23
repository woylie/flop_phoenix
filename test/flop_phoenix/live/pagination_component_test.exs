defmodule Flop.Phoenix.Live.PaginationComponentTest do
  use ExUnit.Case
  use Phoenix.HTML

  import Flop.Phoenix.Factory
  import Phoenix.LiveViewTest

  alias Flop.Phoenix.Live.PaginationComponent
  alias Plug.Conn.Query

  doctest Flop.Phoenix

  @endpoint Flop.Phoenix.Endpoint
  @route_helper_opts [%{}, :pets]

  defp route_helper(%{}, path, query) do
    URI.to_string(%URI{path: "/#{path}", query: Query.encode(query)})
  end

  test "renders pagination wrapper" do
    meta = build(:meta_on_first_page)

    html =
      render_component(PaginationComponent,
        meta: meta,
        route_helper: &route_helper/3,
        route_helper_args: @route_helper_opts,
        opts: []
      )

    assert html =~ ~s(<nav aria-label="pagination" class="pagination" )
    assert html =~ "</nav>"
  end

  test "does not render anything if there is only one page" do
    meta = build(:meta_one_page)

    assert render_component(PaginationComponent,
             meta: meta,
             route_helper: &route_helper/3,
             route_helper_args: @route_helper_opts,
             opts: []
           ) == "\n"
  end

  test "renders previous link" do
    meta = build(:meta_on_second_page)

    assert render_component(PaginationComponent,
             meta: meta,
             route_helper: &route_helper/3,
             route_helper_args: @route_helper_opts,
             opts: []
           ) =~
             ~s(<a class="pagination-previous" data-phx-link="patch" ) <>
               ~s(data-phx-link-state="push" ) <>
               ~s(href="/pets?page=1&amp;page_size=10">Previous</a>)
  end
end
