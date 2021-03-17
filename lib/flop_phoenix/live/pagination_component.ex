defmodule Flop.Phoenix.Live.PaginationComponent do
  use Phoenix.HTML
  use Phoenix.LiveComponent

  alias Flop.Meta
  alias Flop.Phoenix.Pagination

  def render(
        %{
          meta: %Meta{} = meta,
          route_helper: route_helper,
          route_helper_args: route_helper_args,
          opts: opts
        } = assigns
      ) do
    opts = opts |> Pagination.init_opts() |> Keyword.put(:live_view, true)
    attrs = Pagination.build_attrs(opts)

    page_link_helper =
      Pagination.build_page_link_helper(meta, route_helper, route_helper_args)

    ~L"""
    <%= if @meta.total_pages > 1 do %>
      <%= content_tag :nav, attrs do %>
        <%= Pagination.previous_link(meta, page_link_helper, opts) %>
        <%= Pagination.next_link(meta, page_link_helper, opts) %>
        <%= Pagination.page_links(meta, page_link_helper, opts) %>
      <% end %>
    <% end %>
    """
  end
end
