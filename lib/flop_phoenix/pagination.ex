defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  use Phoenix.HTML

  import Phoenix.LiveView.Helpers, only: [live_patch: 2]

  alias Flop.Meta
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

  @spec previous_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def previous_link(%Meta{} = meta, page_link_helper, opts) do
    attrs = opts[:previous_link_attrs]
    content = opts[:previous_link_content]

    if meta.has_previous_page? do
      if event = opts[:event] do
        attrs =
          attrs
          |> Keyword.put(:phx_click, event)
          |> maybe_put_target(opts[:target])
          |> Keyword.put(:phx_value_page, meta.previous_page)
          |> Keyword.put(:to, "#")

        link attrs do
          content
        end
      else
        attrs = Keyword.put(attrs, :to, page_link_helper.(meta.previous_page))

        live_patch attrs do
          content
        end
      end
    else
      attrs = Keyword.put(attrs, :disabled, "disabled")

      content_tag :span, attrs do
        content
      end
    end
  end

  @spec next_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def next_link(%Meta{} = meta, page_link_helper, opts) do
    attrs = opts[:next_link_attrs]
    content = opts[:next_link_content]

    if meta.has_next_page? do
      if event = opts[:event] do
        attrs =
          attrs
          |> Keyword.put(:phx_click, event)
          |> maybe_put_target(opts[:target])
          |> Keyword.put(:phx_value_page, meta.next_page)
          |> Keyword.put(:to, "#")

        link attrs do
          content
        end
      else
        attrs = Keyword.put(attrs, :to, page_link_helper.(meta.next_page))

        live_patch attrs do
          content
        end
      end
    else
      attrs = Keyword.put(attrs, :disabled, "disabled")

      content_tag :span, attrs do
        content
      end
    end
  end

  @spec page_links(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def page_links(meta, route_func, opts) do
    page_link_opt = Keyword.fetch!(opts, :page_links)

    case page_link_opt do
      :hide ->
        raw(nil)

      :all ->
        render_page_links(meta, route_func, meta.total_pages, opts)

      {:ellipsis, max_pages} ->
        render_page_links(meta, route_func, max_pages, opts)
    end
  end

  defp render_page_links(meta, route_func, max_pages, opts) do
    aria_label = opts[:pagination_link_aria_label]
    link_attrs = opts[:pagination_link_attrs]
    current_link_attrs = opts[:current_link_attrs]
    list_attrs = opts[:pagination_list_attrs]
    ellipsis_attrs = opts[:ellipsis_attrs]
    ellipsis_content = opts[:ellipsis_content]

    first..last =
      range =
      get_page_link_range(meta.current_page, max_pages, meta.total_pages)

    start_ellipsis =
      if first > 2,
        do: pagination_ellipsis(ellipsis_attrs, ellipsis_content),
        else: raw(nil)

    end_ellipsis =
      if last < meta.total_pages - 1,
        do: pagination_ellipsis(ellipsis_attrs, ellipsis_content),
        else: raw(nil)

    first_link =
      if first > 1,
        do:
          page_link_tag(
            1,
            meta,
            link_attrs,
            current_link_attrs,
            aria_label,
            route_func,
            opts
          ),
        else: raw(nil)

    last_link =
      if last < meta.total_pages,
        do:
          page_link_tag(
            meta.total_pages,
            meta,
            link_attrs,
            current_link_attrs,
            aria_label,
            route_func,
            opts
          ),
        else: raw(nil)

    links =
      for page <- range do
        page_link_tag(
          page,
          meta,
          link_attrs,
          current_link_attrs,
          aria_label,
          route_func,
          opts
        )
      end

    content_tag :ul, list_attrs do
      [
        first_link,
        start_ellipsis,
        links,
        end_ellipsis,
        last_link
      ]
    end
  end

  defp page_link_tag(
         page,
         meta,
         link_attrs,
         current_link_attrs,
         aria_label,
         route_func,
         opts
       ) do
    attrs =
      if meta.current_page == page, do: current_link_attrs, else: link_attrs

    aria_label = aria_label.(page)

    attrs =
      attrs
      |> Keyword.update(
        :aria,
        [label: aria_label],
        &Keyword.put(&1, :label, aria_label)
      )
      |> Keyword.put(:to, route_func.(page))

    if event = opts[:event] do
      attrs =
        attrs
        |> Keyword.put(:phx_click, event)
        |> maybe_put_target(opts[:target])
        |> Keyword.put(:phx_value_page, page)
        |> Keyword.put(:to, "#")

      content_tag :li do
        link attrs do
          page
        end
      end
    else
      content_tag :li do
        live_patch(page, attrs)
      end
    end
  end

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

  defp pagination_ellipsis(attrs, content) do
    content_tag :li do
      content_tag :span, attrs do
        content
      end
    end
  end

  defp maybe_put_target(attrs, nil), do: attrs

  defp maybe_put_target(attrs, target),
    do: Keyword.put(attrs, :phx_target, target)
end
