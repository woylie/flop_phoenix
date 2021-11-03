defmodule Flop.Phoenix.ViewHelpers do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  import Phoenix.HTML
  import Phoenix.HTML.Form

  def pagination_opts do
    [pagination_list_attrs: [class: "pagination-links"]]
  end

  def table_opts do
    [table_attrs: [class: "sortable-table"]]
  end

  def form_to_html(meta, opts \\ [], function) do
    meta
    |> form_for("/", opts, function)
    |> safe_to_string()
    |> Floki.parse_fragment!()
  end
end
