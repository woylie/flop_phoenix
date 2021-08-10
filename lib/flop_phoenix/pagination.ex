defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  alias Flop.Phoenix.Misc

  @spec default_opts() :: [Flop.Phoenix.pagination_option()]
  def default_opts do
    [
      current_link_attrs: [
        class: "pagination-link is-current",
        aria: [current: "page"]
      ],
      ellipsis_attrs: [class: "pagination-ellipsis"],
      ellipsis_content: raw("&hellip;"),
      next_link_attrs: [class: "pagination-next"],
      next_link_content: "Next",
      page_links: :all,
      pagination_link_aria_label: &"Go to page #{&1}",
      pagination_link_attrs: [class: "pagination-link"],
      pagination_list_attrs: [class: "pagination-list"],
      previous_link_attrs: [class: "pagination-previous"],
      previous_link_content: "Previous",
      wrapper_attrs: [
        class: "pagination",
        role: "navigation",
        aria: [label: "pagination"]
      ]
    ]
  end

  @spec init_opts([Flop.Phoenix.pagination_option()]) :: [
          Flop.Phoenix.pagination_option()
        ]
  def init_opts(opts) do
    Misc.deep_merge(default_opts(), opts)
  end

  @spec render(map) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <nav {@opts[:wrapper_attrs]}>
      <.previous_link
        attrs={@opts[:previous_link_attrs]}
        content={@opts[:previous_link_content]}
        event={@opts[:event]}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
      />
      <.next_link
        attrs={@opts[:next_link_attrs]}
        content={@opts[:next_link_content]}
        event={@opts[:event]}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
      />
      <.page_links
        event={@opts[:event]}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
      />
    </nav>
    """
  end

  defp previous_link(assigns) do
    ~H"""
    <%= if @meta.has_previous_page? do %>
      <%= if @event do %>
        <%= link add_phx_attrs(@attrs, @event, @meta.previous_page, @opts) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <%= live_patch(
          add_to_attr(@attrs, @page_link_helper, @meta.previous_page)
        ) do %>
          <%= @content %>
        <% end %>
      <% end %>
    <% else %>
      <span {Keyword.put(@attrs, :disabled, "disabled")}><%= @content %></span>
    <% end %>
    """
  end

  defp next_link(assigns) do
    ~H"""
    <%= if @meta.has_next_page? do %>
      <%= if @event do %>
        <%= link add_phx_attrs(@attrs, @event, @meta.next_page, @opts) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <%= live_patch(
          add_to_attr(@attrs, @page_link_helper, @meta.next_page)
        ) do %>
          <%= @content %>
        <% end %>
      <% end %>
    <% else %>
      <span {Keyword.put(@attrs, :disabled, "disabled")}><%= @content %></span>
    <% end %>
    """
  end

  defp page_links(assigns) do
    assigns =
      assign(
        assigns,
        :max_pages,
        max_pages(assigns.opts[:page_links], assigns.meta.total_pages)
      )

    ~H"""
    <%= unless @opts[:page_links] == :hide do %>
      <.render_page_links
        max_pages={@max_pages}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
        range={get_page_link_range(
          @meta.current_page,
          @max_pages,
          @meta.total_pages
        )}
      />
    <% end %>
    """
  end

  defp render_page_links(%{range: first..last} = assigns) do
    assigns = assign(assigns, first: first, last: last)

    ~H"""
    <ul {@opts[:pagination_list_attrs]}>
      <%= if @first > 1 do %>
        <.page_link_tag
          aria_label={@opts[:pagination_link_aria_label].(1)}
          attrs={
            if @meta.current_page == 1,
              do: @opts[:current_link_attrs],
              else: @opts[:pagination_link_attrs]
          }
          event={@opts[:event]}
          meta={@meta}
          opts={@opts}
          page={1}
          page_link_helper={@page_link_helper}
        />
      <% end %>

      <%= if @first > 2 do %>
        <.pagination_ellipsis
          attrs={@opts[:ellipsis_attrs]}
          content={@opts[:ellipsis_content]}
        />
      <% end %>

      <%= for page <- @range do %>
        <.page_link_tag
          aria_label={@opts[:pagination_link_aria_label].(page)}
          attrs={
            if @meta.current_page == page,
              do: @opts[:current_link_attrs],
              else: @opts[:pagination_link_attrs]
          }
          event={@opts[:event]}
          meta={@meta}
          opts={@opts}
          page={page}
          page_link_helper={@page_link_helper}
        />
      <% end %>

      <%= if @last < @meta.total_pages - 1 do %>
        <.pagination_ellipsis
          attrs={@opts[:ellipsis_attrs]}
          content={@opts[:ellipsis_content]}
        />
      <% end %>

      <%= if @last < @meta.total_pages do %>
        <.page_link_tag
          aria_label={@opts[:pagination_link_aria_label].(@meta.total_pages)}
          attrs={
            if @meta.current_page == @meta.total_pages,
              do: @opts[:current_link_attrs],
              else: @opts[:pagination_link_attrs]
          }
          event={@opts[:event]}
          meta={@meta}
          opts={@opts}
          page={@meta.total_pages}
          page_link_helper={@page_link_helper}
        />
      <% end %>
    </ul>
    """
  end

  defp page_link_tag(assigns) do
    assigns =
      assign(
        assigns,
        :attrs,
        assigns.attrs
        |> Keyword.update(
          :aria,
          [label: assigns.aria_label],
          &Keyword.put(&1, :label, assigns.aria_label)
        )
        |> Keyword.put(:to, assigns.page_link_helper.(assigns.page))
      )

    ~H"""
    <%= if @event do %>
      <li>
        <%= link @page, add_phx_attrs(@attrs, @event, @page, @opts) %>
      </li>
    <% else %>
      <li><%= live_patch(@page, @attrs) %></li>
    <% end %>
    """
  end

  defp pagination_ellipsis(assigns) do
    ~H"""
    <li><span {@attrs}><%= @content %></span></li>
    """
  end

  defp max_pages(:all, total_pages), do: total_pages
  defp max_pages(:hide, _), do: 0
  defp max_pages({:ellipsis, max_pages}, _), do: max_pages

  defp get_page_link_range(current_page, max_pages, total_pages) do
    # number of additional pages to show before or after current page
    additional = ceil(max_pages / 2)

    cond do
      max_pages >= total_pages ->
        1..total_pages

      current_page + additional >= total_pages ->
        (total_pages - max_pages + 1)..total_pages

      true ->
        first = max(current_page - additional + 1, 1)
        last = min(first + max_pages - 1, total_pages)
        first..last
    end
  end

  def build_page_link_helper(meta, route_helper, route_helper_args, opts) do
    query_params =
      meta.flop
      |> Flop.Phoenix.ensure_page_based_params()
      |> Flop.Phoenix.to_query(opts)

    fn page ->
      params = maybe_put_page(query_params, page)
      Flop.Phoenix.build_path(route_helper, route_helper_args, params)
    end
  end

  defp maybe_put_page(params, 1), do: Keyword.delete(params, :page)
  defp maybe_put_page(params, page), do: Keyword.put(params, :page, page)

  defp add_to_attr(attrs, page_link_helper, page) do
    Keyword.put(attrs, :to, page_link_helper.(page))
  end

  defp add_phx_attrs(attrs, event, page, opts) do
    attrs
    |> Keyword.put(:phx_click, event)
    |> Misc.maybe_put(:phx_target, opts[:target])
    |> Keyword.put(:phx_value_page, page)
    |> Keyword.put(:to, "#")
  end
end
