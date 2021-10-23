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

  @spec init_assigns(map) :: map
  def init_assigns(assigns) do
    assigns =
      assigns
      |> assign_new(:event, fn -> nil end)
      |> assign_new(:for, fn -> nil end)
      |> assign_new(:path_helper, fn -> nil end)
      |> assign_new(:path_helper_args, fn -> nil end)
      |> assign_new(:target, fn -> nil end)
      |> assign(:opts, Misc.deep_merge(default_opts(), assigns[:opts] || []))

    if (assigns.path_helper && assigns.path_helper_args) || assigns.event do
      assigns
    else
      raise """
      Flop.Phoenix.pagination requires either the `path_helper` and
      `path_helper_args` assigns or the `event` assign to be set.

          <Flop.Phoenix.pagination
            meta={@meta}
            path_helper={&Routes.pet_path/3}
            path_helper_args={[@socket, :index]}
          />

      or

          <Flop.Phoenix.pagination
            meta={@meta}
            event="paginate"
          />
      """
    end
  end

  @spec render(map) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <nav {@opts[:wrapper_attrs]}>
      <.previous_link
        attrs={@opts[:previous_link_attrs]}
        content={@opts[:previous_link_content]}
        event={@event}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
        target={@target}
      />
      <.next_link
        attrs={@opts[:next_link_attrs]}
        content={@opts[:next_link_content]}
        event={@event}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
        target={@target}
      />
      <.page_links
        event={@event}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
        target={@target}
      />
    </nav>
    """
  end

  defp previous_link(assigns) do
    ~H"""
    <%= if @meta.has_previous_page? do %>
      <%= if @event do %>
        <%= link add_phx_attrs(@attrs, @event, @target, @meta.previous_page) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <%= live_patch(
          @content,
          add_to_attr(@attrs, @page_link_helper, @meta.previous_page)
        ) %>
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
        <%= link add_phx_attrs(@attrs, @event, @target, @meta.next_page) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <%= live_patch(
          @content,
          add_to_attr(@attrs, @page_link_helper, @meta.next_page)
        ) %>
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
        event={@event}
        max_pages={@max_pages}
        meta={@meta}
        page_link_helper={@page_link_helper}
        opts={@opts}
        range={get_page_link_range(
          @meta.current_page,
          @max_pages,
          @meta.total_pages
        )}
        target={@target}
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
          event={@event}
          meta={@meta}
          opts={@opts}
          page={1}
          page_link_helper={@page_link_helper}
          target={@target}
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
          event={@event}
          meta={@meta}
          opts={@opts}
          page={page}
          page_link_helper={@page_link_helper}
          target={@target}
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
          event={@event}
          meta={@meta}
          opts={@opts}
          page={@meta.total_pages}
          page_link_helper={@page_link_helper}
        />
      <% end %>
    </ul>
    """
  end

  defp page_link_tag(%{meta: meta, opts: opts, page: page} = assigns) do
    assigns = assign(assigns, :attrs, attrs_for_page_link(page, meta, opts))

    ~H"""
    <%= if @event do %>
      <li>
        <%= link @page, add_phx_attrs(@attrs, @event, @target, @page) %>
      </li>
    <% else %>
      <li>
        <%= live_patch(
          @page,
          Keyword.put(@attrs, :to, @page_link_helper.(@page))
        ) %>
      </li>
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

  def build_page_link_helper(meta, route_helper, route_helper_args, for) do
    query_params =
      meta.flop
      |> ensure_page_based_params()
      |> Flop.Phoenix.to_query(for: for)

    fn page ->
      params = maybe_put_page(query_params, page)
      Flop.Phoenix.build_path(route_helper, route_helper_args, params)
    end
  end

  @doc """
  Takes a `Flop` struct and ensures that the only pagination parameters set are
  `:page` and `:page_size`. `:offset` and `:limit` are set to nil.

  ## Examples

      iex> flop = %Flop{limit: 2}
      iex> ensure_page_based_params(flop)
      %Flop{
        limit: nil,
        offset: nil,
        page: nil,
        page_size: 2
      }
  """
  @spec ensure_page_based_params(Flop.t()) :: Flop.t()
  def ensure_page_based_params(%Flop{} = flop) do
    %{
      flop
      | after: nil,
        before: nil,
        first: nil,
        last: nil,
        limit: nil,
        offset: nil,
        page_size: flop.page_size || flop.limit,
        page: flop.page
    }
  end

  defp maybe_put_page(params, 1), do: Keyword.delete(params, :page)
  defp maybe_put_page(params, page), do: Keyword.put(params, :page, page)

  defp attrs_for_page_link(page, meta, opts) do
    attrs =
      if meta.current_page == page,
        do: opts[:current_link_attrs],
        else: opts[:pagination_link_attrs]

    add_page_link_aria_label(attrs, page, opts)
  end

  defp add_to_attr(attrs, page_link_helper, page) do
    Keyword.put(attrs, :to, page_link_helper.(page))
  end

  defp add_phx_attrs(attrs, event, target, page) do
    attrs
    |> Keyword.put(:phx_click, event)
    |> Keyword.put(:phx_value_page, page)
    |> Keyword.put(:to, "#")
    |> Misc.maybe_put(:phx_target, target)
  end

  defp add_page_link_aria_label(attrs, page, opts) do
    aria_label = opts[:pagination_link_aria_label].(page)

    Keyword.update(
      attrs,
      :aria,
      [label: aria_label],
      &Keyword.put(&1, :label, aria_label)
    )
  end
end
