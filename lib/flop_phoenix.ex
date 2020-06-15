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
    opts = Keyword.put_new(opts, :wrapper_class, @wrapper_class)

    page_link_helper =
      build_page_link_helper(meta, route_helper, route_helper_args)

    content_tag :nav,
      class: opts[:wrapper_class],
      role: "navigation",
      aria: [label: "pagination"] do
      [
        previous_link(meta, page_link_helper, opts),
        next_link(meta, page_link_helper, opts),
        page_links(meta, page_link_helper, opts)
      ]
    end
  end

  @spec previous_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def previous_link(%Meta{} = meta, page_link_helper, opts) do
    link_class = opts[:previous_link_class] || @previous_link_class
    content = opts[:previous_link_content] || "Previous"

    if meta.has_previous_page? do
      link class: link_class, to: page_link_helper.(meta.previous_page) do
        content
      end
    else
      content_tag :span, class: link_class, disabled: "disabled" do
        content
      end
    end
  end

  @spec next_link(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def next_link(%Meta{} = meta, page_link_helper, opts) do
    link_class = opts[:next_link_class] || @next_link_class
    content = opts[:next_link_content] || "Next"

    if meta.has_next_page? do
      link class: link_class, to: page_link_helper.(meta.next_page) do
        content
      end
    else
      content_tag :span, class: link_class, disabled: "disabled" do
        content
      end
    end
  end

  @spec page_links(Meta.t(), function, keyword) :: Phoenix.HTML.safe()
  def page_links(meta, route_func, opts \\ []) do
    aria_label = opts[:pagination_link_aria_label] || (&"Goto page #{&1}")
    link_class = opts[:pagination_link_class] || "pagination-link"
    list_class = opts[:pagination_list_class] || "pagination-list"

    content_tag :ul, class: list_class do
      for page <- 1..meta.total_pages do
        class =
          if meta.current_page == page,
            do: "#{link_class} is-current",
            else: link_class

        common_aria = [label: aria_label.(page)]

        aria =
          if meta.current_page == page,
            do: [{:current, "page"} | common_aria],
            else: common_aria

        content_tag :li do
          link(page,
            to: route_func.(page),
            aria: aria,
            class: class
          )
        end
      end
    end
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
