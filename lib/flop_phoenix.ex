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

  def pagination(%Meta{total_pages: 1}, _, _, _), do: raw(nil)

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
        next_link(meta, page_link_helper, opts)
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

  defp build_page_link_helper(meta, route_helper, route_helper_args) do
    fn page ->
      apply(
        route_helper,
        route_helper_args ++ [[page: page, page_size: meta.page_size]]
      )
    end
  end
end
