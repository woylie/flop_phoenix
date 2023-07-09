defmodule Flop.Phoenix.CursorPagination do
  @moduledoc false

  use Phoenix.Component

  alias Flop.Meta
  alias Flop.Phoenix.Misc

  require Logger

  @path_event_error_msg """
  the :path or :event option is required when rendering cursor pagination

  The :path value can be a path as a string, a
  {module, function_name, args} tuple, a {function, args} tuple, or a 1-ary
  function.

  The :event value needs to be a string.

  ## Example

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={~p"/pets"}
      />

  or

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={{Routes, :pet_path, [@socket, :index]}}
      />

  or

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={{&Routes.pet_path/3, [@socket, :index]}}
      />

  or

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={&build_path/1}
      />

  or

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        event="paginate"
      />
  """

  def validate_assigns!(assigns) do
    Misc.validate_path_or_event!(assigns, @path_event_error_msg)
    assigns
  end

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
  def show_link?(%Meta{has_previous_page?: true}, :previous, false), do: true
  def show_link?(%Meta{has_next_page?: true}, :next, false), do: true
  def show_link?(%Meta{has_previous_page?: true}, :next, true), do: true
  def show_link?(%Meta{has_next_page?: true}, :previous, true), do: true
  def show_link?(%Meta{}, _, _), do: false

  def pagination_path(direction, path, %Flop.Meta{} = meta) do
    params =
      meta
      |> Flop.set_cursor(direction)
      |> Flop.Phoenix.to_query(backend: meta.backend, for: meta.schema)

    Flop.Phoenix.build_path(path, params)
  end

  def add_disabled_class(attrs, disabled_class) do
    Keyword.update(attrs, :class, disabled_class, fn class ->
      class <> " " <> disabled_class
    end)
  end
end
