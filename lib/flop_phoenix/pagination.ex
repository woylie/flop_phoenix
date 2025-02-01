defmodule Flop.Phoenix.Pagination do
  @moduledoc false

  alias Flop.Phoenix.Misc

  require Logger

  defstruct [
    :current_page,
    :ellipsis_end?,
    :ellipsis_start?,
    :next_cursor,
    :next_direction,
    :next_page,
    :page_range_end,
    :page_range_start,
    :pagination_type,
    :path_fun,
    :previous_cursor,
    :previous_direction,
    :previous_page,
    :total_pages
  ]

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
      pagination_link_aria_label: &"Go to page #{&1}",
      pagination_link_attrs: [class: "pagination-link"],
      pagination_list_attrs: [class: "pagination-list"],
      pagination_list_item_attrs: [],
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

  def merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:pagination))
    |> Misc.deep_merge(opts)
  end

  def attrs_for_page_link(page, page, opts) do
    add_page_link_aria_label(opts[:current_link_attrs], page, opts)
  end

  def attrs_for_page_link(page, _current_page, opts) do
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
