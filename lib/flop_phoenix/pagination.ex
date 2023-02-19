defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  alias Flop.Phoenix.Misc

  require Logger

  @path_event_error_msg """
  the :path or :event option is required when rendering pagination

  The :path value can be a path as a string, a
  {module, function_name, args} tuple, a {function, args} tuple, or an 1-ary
  function.

  The :event value needs to be a string.

  ## Example

      <Flop.Phoenix.pagination
        meta={@meta}
        path={~p"/pets"}
      />

  or

      <Flop.Phoenix.pagination
        meta={@meta}
        path={{Routes, :pet_path, [@socket, :index]}}
      />

  or

      <Flop.Phoenix.pagination
        meta={@meta}
        path={{&Routes.pet_path/3, [@socket, :index]}}
      />

  or

      <Flop.Phoenix.pagination
        meta={@meta}
        path={&build_path/1}
      />

  or

      <Flop.Phoenix.pagination
        meta={@meta}
        event="paginate"
      />
  """

  @spec default_opts() :: [Flop.Phoenix.pagination_option()]
  def default_opts do
    [
      current_link_attrs: [
        class: "pagination-link is-current",
        aria: [current: "page"]
      ],
      disabled_class: "disabled",
      ellipsis_attrs: [class: "pagination-ellipsis"],
      ellipsis_content: raw("&hellip;"),
      next_link_attrs: [
        aria: [label: "Go to next page"],
        class: "pagination-next"
      ],
      next_link_content: "Next",
      page_links: :all,
      pagination_link_aria_label: &"Go to page #{&1}",
      pagination_link_attrs: [class: "pagination-link"],
      pagination_list_attrs: [class: "pagination-list"],
      previous_link_attrs: [
        aria: [label: "Go to previous page"],
        class: "pagination-previous"
      ],
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
      |> assign(:opts, merge_opts(assigns[:opts] || []))
      |> assign(:path, assigns[:path])

    Misc.validate_path_or_event!(assigns, @path_event_error_msg)
    assigns
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:pagination))
    |> Misc.deep_merge(opts)
  end

  @spec render(map) :: Phoenix.LiveView.Rendered.t()

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true

  def render(assigns) do
    ~H"""
    <nav :if={@meta.errors == []} {@opts[:wrapper_attrs]}>
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

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :content, :any, required: true
  attr :attrs, :list, required: true
  attr :opts, :list, required: true

  defp previous_link(assigns) do
    ~H"""
    <%= if @meta.has_previous_page? do %>
      <%= if @event do %>
        <%= link add_phx_attrs(@attrs, @event, @target, @meta.previous_page) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <.link patch={@page_link_helper.(@meta.previous_page)} {@attrs}>
          <%= @content %>
        </.link>
      <% end %>
    <% else %>
      <span {add_disabled_class(@attrs, @opts[:disabled_class])}>
        <%= @content %>
      </span>
    <% end %>
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :content, :any, required: true
  attr :attrs, :list, required: true
  attr :opts, :list, required: true

  defp next_link(assigns) do
    ~H"""
    <%= if @meta.has_next_page? do %>
      <%= if @event do %>
        <%= link add_phx_attrs(@attrs, @event, @target, @meta.next_page) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <.link patch={@page_link_helper.(@meta.next_page)} {@attrs}>
          <%= @content %>
        </.link>
      <% end %>
    <% else %>
      <span {add_disabled_class(@attrs, @opts[:disabled_class])}>
        <%= @content %>
      </span>
    <% end %>
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true

  defp page_links(assigns) do
    assigns =
      assign(
        assigns,
        :max_pages,
        max_pages(assigns.opts[:page_links], assigns.meta.total_pages)
      )

    ~H"""
    <.render_page_links
      :if={@opts[:page_links] != :hide}
      event={@event}
      meta={@meta}
      page_link_helper={@page_link_helper}
      opts={@opts}
      range={
        get_page_link_range(
          @meta.current_page,
          @max_pages,
          @meta.total_pages
        )
      }
      target={@target}
    />
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true
  attr :range, :any, required: true

  defp render_page_links(%{range: first..last} = assigns) do
    assigns = assign(assigns, first: first, last: last)

    ~H"""
    <ul {@opts[:pagination_list_attrs]}>
      <.page_link_tag
        :if={@first > 1}
        event={@event}
        meta={@meta}
        opts={@opts}
        page={1}
        page_link_helper={@page_link_helper}
        target={@target}
      />

      <.pagination_ellipsis
        :if={@first > 2}
        attrs={@opts[:ellipsis_attrs]}
        content={@opts[:ellipsis_content]}
      />

      <.page_link_tag
        :for={page <- @range}
        event={@event}
        meta={@meta}
        opts={@opts}
        page={page}
        page_link_helper={@page_link_helper}
        target={@target}
      />

      <.pagination_ellipsis
        :if={@last < @meta.total_pages - 1}
        attrs={@opts[:ellipsis_attrs]}
        content={@opts[:ellipsis_content]}
      />

      <.page_link_tag
        :if={@last < @meta.total_pages}
        event={@event}
        meta={@meta}
        opts={@opts}
        page={@meta.total_pages}
        page_link_helper={@page_link_helper}
        target={@target}
      />
    </ul>
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true
  attr :page, :integer, required: true

  defp page_link_tag(%{meta: meta, opts: opts, page: page} = assigns) do
    assigns = assign(assigns, :attrs, attrs_for_page_link(page, meta, opts))

    ~H"""
    <%= if @event do %>
      <li>
        <%= link(@page, add_phx_attrs(@attrs, @event, @target, @page)) %>
      </li>
    <% else %>
      <li>
        <.link patch={@page_link_helper.(@page)} {@attrs}>
          <%= @page %>
        </.link>
      </li>
    <% end %>
    """
  end

  attr :attrs, :list, required: true
  attr :content, :any, required: true

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

  def build_page_link_helper(meta, path) do
    query_params = build_query_params(meta)

    fn page ->
      params = maybe_put_page(query_params, page)
      Flop.Phoenix.build_path(path, params)
    end
  end

  defp build_query_params(meta) do
    meta.flop
    |> ensure_page_based_params()
    |> Flop.Phoenix.to_query(backend: meta.backend, for: meta.schema)
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

  defp add_phx_attrs(attrs, event, target, page) do
    attrs
    |> Keyword.put(:phx_click, event)
    |> Keyword.put(:phx_value_page, page)
    |> Keyword.put(:to, "#")
    |> Misc.maybe_put(:phx_target, target)
  end

  defp add_disabled_class(attrs, disabled_class) do
    Keyword.update(attrs, :class, disabled_class, fn class ->
      class <> " " <> disabled_class
    end)
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
