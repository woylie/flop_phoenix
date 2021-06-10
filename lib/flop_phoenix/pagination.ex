defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  use Phoenix.HTML

  import Phoenix.LiveView.Helpers, only: [live_patch: 2]

  alias Flop.Meta

  @current_link_class "pagination-link is-current"
  @ellipsis_class "pagination-ellipsis"
  @link_class "pagination-link"
  @next_link_class "pagination-next"
  @pagination_list_class "pagination-list"
  @previous_link_class "pagination-previous"
  @wrapper_class "pagination"

  @next_link_content "Next"
  @previous_link_content "Previous"

  def init_opts(opts) do
    Keyword.put_new(opts || [], :page_links, :all)
  end

  def build_attrs(opts) do
    opts
    |> Keyword.get(:wrapper_attrs, [])
    |> Keyword.put_new(:class, @wrapper_class)
    |> Keyword.put_new(:role, "navigation")
    |> Keyword.put_new(:aria, label: "pagination")
  end

  def build_page_link_helper(meta, route_helper, route_helper_args) do
    query_params =
      meta.flop |> ensure_page_based_params() |> Flop.Phoenix.to_query()

    fn page ->
      params = Keyword.put(query_params, :page, page)
      Flop.Phoenix.build_path(route_helper, route_helper_args, params)
    end
  end

  defp ensure_page_based_params(%Flop{} = flop) do
    # using default_limit without passing a page parameter produces a Flop
    # with only the limit set

    %{
      flop
      | limit: nil,
        offset: nil,
        page_size: flop.page_size || flop.limit,
        page: flop.page
    }
  end

  @spec previous_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def previous_link(%Meta{} = meta, page_link_helper, opts) do
    attrs =
      opts
      |> Keyword.get(:previous_link_attrs, [])
      |> Keyword.put_new(:class, @previous_link_class)

    content = opts[:previous_link_content] || @previous_link_content

    if meta.has_previous_page? do
      attrs = Keyword.put(attrs, :to, page_link_helper.(meta.previous_page))

      live_patch attrs do
        content
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
    attrs =
      opts
      |> Keyword.get(:next_link_attrs, [])
      |> Keyword.put_new(:class, @next_link_class)

    content = opts[:next_link_content] || @next_link_content

    if meta.has_next_page? do
      attrs = Keyword.put(attrs, :to, page_link_helper.(meta.next_page))

      live_patch attrs do
        content
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
    aria_label = opts[:pagination_link_aria_label] || (&"Goto page #{&1}")

    link_attrs =
      opts
      |> Keyword.get(:pagination_link_attrs, [])
      |> Keyword.put_new(:class, @link_class)
      |> Keyword.put_new(:aria, [])

    current_link_attrs =
      opts
      |> Keyword.get(:current_link_attrs, [])
      |> Keyword.put_new(:class, @current_link_class)
      |> Keyword.put_new(:aria, current: "page")

    list_attrs =
      opts
      |> Keyword.get(:pagination_list_attrs, [])
      |> Keyword.put_new(:class, @pagination_list_class)

    ellipsis_attrs =
      opts
      |> Keyword.get(:ellipsis_attrs, [])
      |> Keyword.put_new(:class, @ellipsis_class)

    ellipsis_content = Keyword.get(opts, :ellipsis_content, raw("&hellip;"))

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
            route_func
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
            route_func
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
          route_func
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
         route_func
       ) do
    attrs =
      if meta.current_page == page, do: current_link_attrs, else: link_attrs

    attrs =
      attrs
      |> Keyword.update!(
        :aria,
        &Keyword.put(&1, :label, aria_label.(page))
      )
      |> Keyword.put(:to, route_func.(page))

    content_tag :li do
      live_patch(page, attrs)
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
end
