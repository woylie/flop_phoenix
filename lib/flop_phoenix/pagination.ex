defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  use Phoenix.HTML

  alias Flop.Meta

  @next_link_class "pagination-next"
  @previous_link_class "pagination-previous"
  @wrapper_class "pagination"

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
    filter_map =
      meta.flop.filters
      |> Stream.with_index()
      |> Enum.into(%{}, fn {filter, index} ->
        {index, Map.from_struct(filter)}
      end)

    query_params =
      []
      |> maybe_add_param(:filters, filter_map)
      |> maybe_add_param(:order_by, meta.flop.order_by)
      |> maybe_add_param(:order_directions, meta.flop.order_directions)
      |> maybe_add_param(:page_size, meta.page_size)

    fn page ->
      apply(
        route_helper,
        route_helper_args ++ [Keyword.put(query_params, :page, page)]
      )
    end
  end

  @spec previous_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def previous_link(%Meta{} = meta, page_link_helper, opts) do
    attrs =
      opts
      |> Keyword.get(:previous_link_attrs, [])
      |> Keyword.put_new(:class, @previous_link_class)

    content = opts[:previous_link_content] || "Previous"

    if meta.has_previous_page? do
      attrs = Keyword.put(attrs, :to, page_link_helper.(meta.previous_page))

      link attrs do
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

    content = opts[:next_link_content] || "Next"

    if meta.has_next_page? do
      attrs = Keyword.put(attrs, :to, page_link_helper.(meta.next_page))

      link attrs do
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
      |> Keyword.put_new(:class, "pagination-link")
      |> Keyword.put_new(:aria, [])

    list_attrs =
      opts
      |> Keyword.get(:pagination_list_attrs, [])
      |> Keyword.put_new(:class, "pagination-list")

    ellipsis_class =
      opts
      |> Keyword.get(:ellipsis_attrs, [])
      |> Keyword.put_new(:class, "pagination-ellipsis")

    ellipsis_content = Keyword.get(opts, :ellipsis_content, raw("&hellip;"))

    first..last =
      range =
      get_page_link_range(meta.current_page, max_pages, meta.total_pages)

    start_ellipsis =
      if first > 1,
        do: pagination_ellipsis(ellipsis_class, ellipsis_content),
        else: raw(nil)

    end_ellipsis =
      if last < meta.total_pages,
        do: pagination_ellipsis(ellipsis_class, ellipsis_content),
        else: raw(nil)

    links =
      for page <- range do
        attrs =
          link_attrs
          |> Keyword.update!(
            :aria,
            &Keyword.put(&1, :label, aria_label.(page))
          )
          |> add_current_attrs(meta.current_page == page)
          |> Keyword.put(:to, route_func.(page))

        content_tag :li do
          link(page, attrs)
        end
      end

    content_tag :ul, list_attrs do
      [start_ellipsis, links, end_ellipsis]
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

  defp add_current_attrs(attrs, false), do: attrs

  defp add_current_attrs(attrs, true) do
    attrs
    |> Keyword.update!(:aria, &Keyword.put(&1, :current, "page"))
    |> Keyword.update!(:class, &"#{&1} is-current")
  end

  defp maybe_add_param(params, _, nil), do: params
  defp maybe_add_param(params, _, []), do: params
  defp maybe_add_param(params, key, value), do: Keyword.put(params, key, value)
end
