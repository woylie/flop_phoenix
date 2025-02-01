defmodule Flop.Phoenix.Pagination do
  @moduledoc """
  Defines a struct that holds the information needed to render a pagination
  component.
  """

  alias Flop.Phoenix.Misc

  require Logger

  @typedoc """
  Describes the data needed to render a pagination component.

  ## For page-based pagination

  - `current_page`
  - `ellipsis_end?` - Whether an ellipsis should be rendered between the middle
    pagination links and the link to the last page.
  - `ellipsis_end?` - Whether an ellipsis should be rendered between the link to
    the first page and the middle pagination links.
  - `next_page`
  - `page_range_start`, `page_range_end` - The range for the links for
    individual pages.
  - `pagination_type` - In the case of page-based pagination, this is either
    `:page` or `:offset`.
  - `path_fun` - 1-arity function that takes a page number and returns a path
    to that page that also includes query parameters for filters and sorting.
  - `previous_page`
  - `total_pages`


  ## For cursor-based pagination

  - `next_cursor` - The cursor to be used for the link to the next page.
    Depending on the value of the `reverse` option, this is either the start
    cursor or the end cursor of the `Flop.Meta` struct.
  - `next_direction` - The pagination direction for the link to the next page.
    If the `reverse` option is set to `true`, this will be `:previous`.
  - `pagination_type` - In the case of cursor-based pagination, this is either
    `:first` or `:last`.
  - `path_fun` - 2-arity function that takes a cursor and a direction and
    returns a path to that page that also includes query parameters for filters
    and sorting.
  - `previous_cursor` - The cursor to be used for the link to the previous page.
    Depending on the value of the `reverse` option, this is either the start
    cursor or the end cursor of the `Flop.Meta` struct.
  """
  @type t :: %__MODULE__{
          current_page: pos_integer | nil,
          ellipsis_end?: boolean,
          ellipsis_start?: boolean,
          next_cursor: String.t() | nil,
          next_direction: :previous | :next,
          next_page: pos_integer | nil,
          page_range_end: pos_integer | nil,
          page_range_start: pos_integer | nil,
          pagination_type: Flop.pagination_type(),
          path_fun:
            (pos_integer | nil -> String.t())
            | (String.t() | nil, :previous | :next -> String.t()),
          previous_cursor: String.t() | nil,
          previous_direction: :previous | :next,
          previous_page: pos_integer | nil,
          total_pages: pos_integer | nil
        }

  defstruct [
    :current_page,
    :next_cursor,
    :next_page,
    :page_range_end,
    :page_range_start,
    :pagination_type,
    :path_fun,
    :previous_cursor,
    :previous_page,
    :total_pages,
    ellipsis_end?: false,
    ellipsis_start?: false,
    next_direction: :next,
    previous_direction: :previous
  ]

  @doc false
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

  @doc false
  def merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:pagination))
    |> Misc.deep_merge(opts)
  end

  @doc false
  def attrs_for_page_link(page, page, opts) do
    add_page_link_aria_label(opts[:current_link_attrs], page, opts)
  end

  @doc false
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
