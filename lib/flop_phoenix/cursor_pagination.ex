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

  def build_page_link_fun(_meta, nil), do: fn _, _ -> nil end

  def build_page_link_fun(meta, path) do
    &build_path(path, &1, &2, build_query_params(meta))
  end

  defp build_query_params(meta) do
    meta.flop
    |> ensure_cursor_based_params()
    |> Flop.Phoenix.to_query(backend: meta.backend, for: meta.schema)
  end

  defp build_path(path, cursor, direction, query_params) do
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
end
