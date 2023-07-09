defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  use Phoenix.Component

  alias Flop.Phoenix.Misc
  alias Phoenix.LiveView.JS

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
        on_paginate={JS.push("paginate")}
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
      ellipsis_content: Phoenix.HTML.raw("&hellip;"),
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
  def init_assigns(%{meta: meta, opts: opts, path: path} = assigns) do
    Misc.validate_path_or_event!(assigns, @path_event_error_msg)

    assigns
    |> assign(:opts, merge_opts(opts))
    |> assign(:page_link_helper, build_page_link_helper(meta, path))
    |> assign(:path, nil)
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:pagination))
    |> Misc.deep_merge(opts)
  end

  attr :path, :string
  attr :on_paginate, JS
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :page, :integer, required: true
  attr :disabled, :boolean, default: false
  attr :disabled_class, :string
  attr :rest, :global
  slot :inner_block

  def pagination_link(
        %{disabled: true, disabled_class: disabled_class} = assigns
      ) do
    rest =
      Map.update(assigns.rest, :class, disabled_class, fn class ->
        [class, disabled_class]
      end)

    assigns = assign(assigns, :rest, rest)

    ~H"""
    <span {@rest} class={@disabled_class}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  def pagination_link(%{event: event} = assigns) when is_binary(event) do
    ~H"""
    <.link phx-click={@event} phx-target={@target} phx-value-page={@page} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def pagination_link(%{on_paginate: nil, path: path} = assigns)
      when is_binary(path) do
    ~H"""
    <.link patch={@path} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def pagination_link(%{} = assigns) do
    ~H"""
    <.link
      href={@path}
      phx-click={click_cmd(@on_paginate, @path)}
      phx-target={@target}
      phx-value-page={@page}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp click_cmd(on_paginate, nil), do: on_paginate
  defp click_cmd(on_paginate, path), do: JS.patch(on_paginate, path)

  attr :meta, Flop.Meta, required: true
  attr :on_paginate, JS
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true

  def page_links(%{meta: meta} = assigns) do
    max_pages = max_pages(assigns.opts[:page_links], assigns.meta.total_pages)

    range =
      first..last =
      get_page_link_range(meta.current_page, max_pages, meta.total_pages)

    assigns = assign(assigns, first: first, last: last, range: range)

    ~H"""
    <ul :if={@opts[:page_links] != :hide} {@opts[:pagination_list_attrs]}>
      <.pagination_link
        :if={@first > 1}
        event={@event}
        target={@target}
        page={1}
        path={@page_link_helper.(1)}
        on_paginate={@on_paginate}
        {attrs_for_page_link(1, @meta, @opts)}
      >
        1
      </.pagination_link>

      <.pagination_ellipsis :if={@first > 2} {@opts[:ellipsis_attrs]}>
        <%= @opts[:ellipsis_content] %>
      </.pagination_ellipsis>

      <.pagination_link
        :for={page <- @range}
        event={@event}
        target={@target}
        page={page}
        path={@page_link_helper.(page)}
        on_paginate={@on_paginate}
        {attrs_for_page_link(page, @meta, @opts)}
      >
        <%= page %>
      </.pagination_link>

      <.pagination_ellipsis
        :if={@last < @meta.total_pages - 1}
        {@opts[:ellipsis_attrs]}
      >
        <%= @opts[:ellipsis_content] %>
      </.pagination_ellipsis>

      <.pagination_link
        :if={@last < @meta.total_pages}
        event={@event}
        target={@target}
        page={@meta.total_pages}
        path={@page_link_helper.(@meta.total_pages)}
        on_paginate={@on_paginate}
        {attrs_for_page_link(@meta.total_pages, @meta, @opts)}
      >
        <%= @meta.total_pages %>
      </.pagination_link>
    </ul>
    """
  end

  attr :rest, :global
  slot :inner_block

  defp pagination_ellipsis(assigns) do
    ~H"""
    <li><span {@rest}><%= render_slot(@inner_block) %></span></li>
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

  def build_page_link_helper(_meta, nil), do: fn _ -> nil end

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

  defp attrs_for_page_link(page, %{current_page: page}, opts) do
    add_page_link_aria_label(opts[:current_link_attrs], page, opts)
  end

  defp attrs_for_page_link(page, _meta, opts) do
    add_page_link_aria_label(opts[:pagination_link_attrs], page, opts)
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
