defmodule Flop.Phoenix.Pagination do
  @moduledoc """
  Defines a struct that holds the information needed to render a pagination
  component.
  """

  alias Flop.Meta
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

  @doc """
  Returns a `Pagination` struct for the given `Flop.Meta` struct.

  ## Options

  - `page_links` - Defines how many page links to render. Only used for
    page-based pagination. Default: `5`.
  - `path` - The path to the current page in the format as accepted by
    `Flop.Phoenix.build_path/3`. Default: `nil`.
  - `reverse` - Reverses the position of the previous and next link. Only used
    for cursor-based pagination. Default: `false`.
  """
  @spec new(Meta.t(), keyword) :: t
  def new(meta, opts \\ [])

  def new(
        %Flop.Meta{
          errors: [],
          has_next_page?: has_next_page?,
          has_previous_page?: has_previous_page?,
          total_pages: total_pages
        } = meta,
        opts
      )
      when has_next_page? or has_previous_page? do
    opts = Keyword.validate!(opts, page_links: 5, path: nil, reverse: false)
    page_links = Keyword.fetch!(opts, :page_links)
    path = Keyword.fetch!(opts, :path)
    reverse = Keyword.fetch!(opts, :reverse)
    pagination_type = pagination_type(meta.flop)

    if pagination_type in [:page, :offset] do
      path_fun = build_page_path_fun(meta, path)

      {page_range_start, page_range_end} =
        Flop.Phoenix.page_link_range(
          page_links,
          meta.current_page,
          meta.total_pages
        )

      %__MODULE__{
        current_page: meta.current_page,
        ellipsis_end?: page_range_end < meta.total_pages - 1,
        ellipsis_start?: page_range_start > 2,
        next_page: meta.next_page,
        page_range_end: page_range_end,
        path_fun: path_fun,
        page_range_start: page_range_start,
        pagination_type: pagination_type,
        previous_page: meta.previous_page,
        total_pages: total_pages
      }
    else
      previous_cursor = if has_previous_page?, do: meta.start_cursor
      next_cursor = if has_next_page?, do: meta.end_cursor
      path_fun = build_cursor_path_fun(meta, path)

      {previous_direction, previous_cursor, next_direction, next_cursor} =
        if reverse do
          {:next, next_cursor, :previous, previous_cursor}
        else
          {:previous, previous_cursor, :next, next_cursor}
        end

      %__MODULE__{
        next_cursor: next_cursor,
        next_direction: next_direction,
        path_fun: path_fun,
        pagination_type: pagination_type,
        previous_cursor: previous_cursor,
        previous_direction: previous_direction
      }
    end
  end

  def new(%Meta{flop: flop}, _) do
    %__MODULE__{pagination_type: pagination_type(flop)}
  end

  defp pagination_type(%Flop{first: first}) when is_integer(first) do
    :first
  end

  defp pagination_type(%Flop{last: last}) when is_integer(last) do
    :last
  end

  defp pagination_type(%Flop{limit: limit}) when is_integer(limit) do
    :offset
  end

  defp pagination_type(%Flop{page_size: page_size})
       when is_integer(page_size) do
    :page
  end

  defp build_page_path_fun(_meta, nil), do: fn _ -> nil end

  defp build_page_path_fun(meta, path) do
    &build_page_path(path, &1, build_page_query_params(meta))
  end

  defp build_page_query_params(meta) do
    meta.flop
    |> ensure_page_based_params()
    |> Flop.Phoenix.to_query(backend: meta.backend, for: meta.schema)
  end

  defp build_page_path(path, page, query_params) do
    Flop.Phoenix.build_path(path, maybe_put_page(query_params, page))
  end

  defp ensure_page_based_params(%Flop{} = flop) do
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

  defp build_cursor_path_fun(_meta, nil), do: fn _, _ -> nil end

  defp build_cursor_path_fun(meta, path) do
    &build_cursor_path(path, &1, &2, build_cursor_query_params(meta))
  end

  defp build_cursor_query_params(meta) do
    meta.flop
    |> ensure_cursor_based_params()
    |> Flop.Phoenix.to_query(backend: meta.backend, for: meta.schema)
  end

  defp build_cursor_path(path, cursor, direction, query_params) do
    Flop.Phoenix.build_path(
      path,
      maybe_put_cursor(query_params, cursor, direction)
    )
  end

  defp ensure_cursor_based_params(%Flop{} = flop) do
    %{
      flop
      | after: nil,
        before: nil,
        limit: nil,
        offset: nil,
        page_size: nil,
        page: nil
    }
  end

  defp maybe_put_cursor(query_params, nil, _), do: query_params

  defp maybe_put_cursor(query_params, cursor, :previous) do
    query_params
    |> Keyword.merge(
      before: cursor,
      last: query_params[:last] || query_params[:first],
      first: nil
    )
    |> Keyword.delete(:first)
  end

  defp maybe_put_cursor(query_params, cursor, :next) do
    query_params
    |> Keyword.merge(
      after: cursor,
      first: query_params[:first] || query_params[:last]
    )
    |> Keyword.delete(:last)
  end

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
