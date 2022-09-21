defmodule Flop.Phoenix.CursorPagination do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  alias Flop.Phoenix.Misc

  require Logger

  @path_event_error_msg """
  the :path or :event option is required when rendering cursor pagination

  The :path value can be a path as a string, a
  {module, function_name, args} tuple or a {function, args} tuple.

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
        event="paginate"
      />
  """

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

  @spec init_assigns(map) :: map
  def init_assigns(assigns) do
    assigns =
      assigns
      |> assign(:opts, merge_opts(assigns[:opts] || []))
      |> assign(:path, assigns[:path] || assigns[:path_helper])

    if assigns[:path_helper] do
      Logger.debug(
        "The `path_helper` assign is deprecated. Use `path` instead."
      )
    end

    Misc.validate_path_or_event!(assigns, @path_event_error_msg)
    assigns
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:cursor_pagination))
    |> Misc.deep_merge(opts)
  end

  attr :meta, Flop.Meta, required: true
  attr :direction, :atom, required: true
  attr :attrs, :list, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :path, :any, required: true
  attr :content, :any, required: true
  attr :opts, :list, required: true

  def render_link(assigns) do
    ~H"""
    <%= if show_link?(@meta, @direction) do %>
      <%= if @event do %>
        <%= link add_phx_attrs(@attrs, @event, @target, @direction) do %>
          <%= @content %>
        <% end %>
      <% else %>
        <.link patch={pagination_path(@direction, @path, @meta)} {@attrs}>
          <%= @content %>
        </.link>
      <% end %>
    <% else %>
      <span {add_disabled_class(@attrs, @opts[:disabled_class])}>
        <%= @content %>
      </span>
    <% end %>
    """
  end

  defp show_link?(%Flop.Meta{has_previous_page?: true}, :previous), do: true
  defp show_link?(%Flop.Meta{has_next_page?: true}, :next), do: true
  defp show_link?(%Flop.Meta{}, _), do: false

  defp pagination_path(direction, path, %Flop.Meta{} = meta) do
    params =
      meta
      |> Flop.set_cursor(direction)
      |> Flop.Phoenix.to_query(for: meta.schema)

    Flop.Phoenix.build_path(path, params)
  end

  defp add_phx_attrs(attrs, event, target, direction) do
    attrs
    |> Keyword.put(:phx_click, event)
    |> Keyword.put(:phx_value_to, direction)
    |> Keyword.put(:to, "#")
    |> Misc.maybe_put(:phx_target, target)
  end

  defp add_disabled_class(attrs, disabled_class) do
    Keyword.update(attrs, :class, disabled_class, fn class ->
      class <> " " <> disabled_class
    end)
  end
end
