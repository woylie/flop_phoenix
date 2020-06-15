defmodule FlopPhoenix do
  @moduledoc """
  View helper functions for Phoenix and Flop.
  """

  use Phoenix.HTML

  alias Flop.Meta

  @next_link_class "pagination-next"
  @previous_link_class "pagination-previous"
  @wrapper_class "pagination"

  @spec pagination(Meta.t(), function, [any], keyword) ::
          Phoenix.HTML.safe()

  def pagination(meta, route_helper, route_helper_args, opts \\ [])

  def pagination(%Meta{total_pages: p}, _, _, _) when p <= 1, do: raw(nil)

  def pagination(%Meta{} = meta, route_helper, route_helper_args, opts) do
    attrs =
      opts
      |> Keyword.get(:wrapper_attrs, [])
      |> Keyword.put_new(:class, @wrapper_class)
      |> Keyword.put_new(:role, "navigation")
      |> Keyword.put_new(:aria, label: "pagination")

    page_link_helper =
      build_page_link_helper(meta, route_helper, route_helper_args)

    content_tag :nav, attrs do
      [
        previous_link(meta, page_link_helper, opts),
        next_link(meta, page_link_helper, opts),
        page_links(meta, page_link_helper, opts)
      ]
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
  def page_links(meta, route_func, opts \\ []) do
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

    content_tag :ul, list_attrs do
      for page <- 1..meta.total_pages do
        attrs =
          link_attrs
          |> Keyword.update!(:aria, &Keyword.put(&1, :label, aria_label.(page)))
          |> add_current_attrs(meta.current_page == page)
          |> Keyword.put(:to, route_func.(page))

        content_tag :li do
          link(page, attrs)
        end
      end
    end
  end

  defp add_current_attrs(attrs, false), do: attrs

  defp add_current_attrs(attrs, true) do
    attrs
    |> Keyword.update!(:aria, &Keyword.put(&1, :current, "page"))
    |> Keyword.update!(:class, &"#{&1} is-current")
  end

  defp build_page_link_helper(meta, route_helper, route_helper_args) do
    fn page ->
      apply(
        route_helper,
        route_helper_args ++ [[page: page, page_size: meta.page_size]]
      )
    end
  end
end
