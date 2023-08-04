defmodule Flop.Phoenix.CursorPagination do
  @moduledoc false

  use Phoenix.Component

  alias Flop.Meta
  alias Flop.Phoenix.Misc

  require Logger

  @spec default_opts() :: [Flop.Phoenix.cursor_pagination_option()]
  def default_opts do
    [
      disabled_class: "disabled",
      next_link_attrs: [
        aria: [label: "Go to next page"],
        class: "pagination-next"
      ],
      next_link_content: "Next",
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
    |> Misc.deep_merge(Misc.get_global_opts(:cursor_pagination))
    |> Misc.deep_merge(opts)
  end

  # meta, direction, reverse
  def disable?(%Meta{has_previous_page?: true}, :previous, false), do: false
  def disable?(%Meta{has_next_page?: true}, :next, false), do: false
  def disable?(%Meta{has_previous_page?: true}, :next, true), do: false
  def disable?(%Meta{has_next_page?: true}, :previous, true), do: false
  def disable?(%Meta{}, _, _), do: true

  def pagination_path(_, nil, _), do: nil

  def pagination_path(direction, path, %Flop.Meta{} = meta) do
    params =
      meta
      |> Flop.set_cursor(direction)
      |> Flop.Phoenix.to_query(backend: meta.backend, for: meta.schema)

    Flop.Phoenix.build_path(path, params)
  end
end
