defmodule Flop.Phoenix.ViewHelpers do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  def pagination_opts do
    [pagination_list_attrs: [class: "pagination-links"]]
  end

  def table_opts do
    [table_attrs: [class: "sortable-table"]]
  end
end
