defmodule Flop.Phoenix.CursorPagination do
  @moduledoc false

  use Phoenix.Component

  require Logger

  def build_path_fun(_meta, nil), do: fn _, _ -> nil end

  def build_path_fun(meta, path) do
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
