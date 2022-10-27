defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  alias Flop.Phoenix.Misc
  alias Phoenix.LiveView.JS

  require Logger

  @path_event_error_msg """
  the :path or :event option is required when rendering a table

  The :path value can be a {module, function_name, args} tuple, a
  {function, args} tuple, or a 1-ary function.

  The :event value needs to be a string.

  ## Examples

      <Flop.Phoenix.table
        items={@pets}
        meta={@meta}
        path={~p"/pets"}
      >

  or

      <Flop.Phoenix.table
        items={@pets}
        meta={@meta}
        path={{Routes, :pet_path, [@socket, :index]}}
      >

  or

      <Flop.Phoenix.table
        items={@pets}
        meta={@meta}
        path={{&Routes.pet_path/3, [@socket, :index]}}
      >

  or

      <Flop.Phoenix.table
        items={@pets}
        meta={@meta}
        path={&build_path/1}
      >

  or

      <Flop.Phoenix.table
        items={@pets}
        meta={@meta}
        event="sort-table"
      >
  """

  @spec default_opts() :: [Flop.Phoenix.table_option()]
  def default_opts do
    [
      container: false,
      container_attrs: [class: "table-container"],
      no_results_content: content_tag(:p, do: "No results."),
      symbol_asc: "▴",
      symbol_attrs: [class: "order-direction"],
      symbol_desc: "▾",
      symbol_unsorted: nil,
      table_attrs: [],
      tbody_attrs: [],
      tbody_td_attrs: [],
      tbody_tr_attrs: [],
      th_wrapper_attrs: [],
      thead_th_attrs: [],
      thead_tr_attrs: []
    ]
  end

  @doc """
  Deep merges the given options into the default options.
  """
  @spec init_assigns(map) :: map
  def init_assigns(assigns) do
    assigns =
      assigns
      |> assign(:opts, merge_opts(assigns[:opts] || []))
      |> assign(:path, assigns[:path] || assigns[:path_helper])

    Misc.validate_path_or_event!(assigns, @path_event_error_msg)
    assigns
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:table))
    |> Misc.deep_merge(opts)
  end

  attr :meta, Flop.Meta, required: true
  attr :path, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :caption, :string, required: true
  attr :opts, :any, required: true
  attr :col, :any, required: true
  attr :items, :list, required: true
  attr :foot, :any, required: true
  attr :row_click, JS, default: nil
  attr :action, :any, required: true

  def render(assigns) do
    ~H"""
    <table {@opts[:table_attrs]}>
      <%= if @caption do %>
        <caption><%= @caption %></caption>
      <% end %>
      <%= if Enum.any?(@col, & &1[:col_style]) or Enum.any?(@action, & &1[:col_style]) do %>
        <colgroup>
          <%= for col <- @col do %>
            <col :if={show_column?(col)} style={col[:col_style]} />
          <% end %>
          <%= for action <- @action do %>
            <col :if={show_column?(action)} style={action[:col_style]} />
          <% end %>
        </colgroup>
      <% end %>
      <thead>
        <tr {@opts[:thead_tr_attrs]}>
          <%= for col <- @col do %>
            <%= if show_column?(col) do %>
              <.header_column
                event={@event}
                field={col[:field]}
                label={col[:label]}
                meta={@meta}
                opts={@opts}
                path={@path}
                target={@target}
              />
            <% end %>
          <% end %>
          <%= for action <- @action do %>
            <%= if show_column?(action) do %>
              <.header_column
                event={@event}
                field={nil}
                label={action[:label]}
                meta={@meta}
                opts={@opts}
                path={nil}
                target={@event}
              />
            <% end %>
          <% end %>
        </tr>
      </thead>
      <tbody {@opts[:tbody_attrs]}>
        <tr :for={item <- @items} {@opts[:tbody_tr_attrs]}>
          <%= for col <- @col do %>
            <%= if show_column?(col) do %>
              <td
                {@opts[:tbody_td_attrs]}
                {Map.get(col, :attrs, [])}
                phx-click={@row_click && @row_click.(item)}
              >
                <%= render_slot(col, item) %>
              </td>
            <% end %>
          <% end %>
          <%= for action <- @action do %>
            <td
              {@opts[:tbody_td_attrs]}
              {Map.get(action, :attrs, [])}
            >
              <%= render_slot(action, item) %>
            </td>
          <% end %>
        </tr>
      </tbody>
      <%= if @foot && @foot != [] do %>
        <tfoot><%= render_slot(@foot) %></tfoot>
      <% end %>
    </table>
    """
  end

  defp show_column?(%{hide: true}), do: false
  defp show_column?(%{show: false}), do: false
  defp show_column?(_), do: true

  attr :meta, Flop.Meta, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :path, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :any, required: true

  defp header_column(assigns) do
    index = order_index(assigns.meta.flop, assigns.field)
    direction = order_direction(assigns.meta.flop.order_directions, index)

    assigns =
      assigns
      |> assign(:order_index, index)
      |> assign(:order_direction, direction)

    ~H"""
    <%= if is_sortable?(@field, @meta.schema) do %>
      <th
        {@opts[:thead_th_attrs]}
        aria-sort={aria_sort(@order_index, @order_direction)}
      >
        <span {@opts[:th_wrapper_attrs]}>
          <%= if @event do %>
            <.sort_link
              event={@event}
              field={@field}
              label={@label}
              target={@target}
            />
          <% else %>
            <.link patch={
              Flop.Phoenix.build_path(
                @path,
                Flop.push_order(@meta.flop, @field),
                backend: @meta.backend,
                for: @meta.schema
              )
            }>
              <%= @label %>
            </.link>
          <% end %>
          <.arrow direction={@order_direction} opts={@opts} />
        </span>
      </th>
    <% else %>
      <th {@opts[:thead_th_attrs]}><%= @label %></th>
    <% end %>
    """
  end

  defp aria_sort(0, direction), do: direction_to_aria(direction)
  defp aria_sort(_, _), do: nil

  defp direction_to_aria(:desc), do: "descending"
  defp direction_to_aria(:desc_nulls_last), do: "descending"
  defp direction_to_aria(:desc_nulls_first), do: "descending"
  defp direction_to_aria(:asc), do: "ascending"
  defp direction_to_aria(:asc_nulls_last), do: "ascending"
  defp direction_to_aria(:asc_nulls_first), do: "ascending"

  attr :direction, :atom, required: true
  attr :opts, :list, required: true

  defp arrow(assigns) do
    ~H"""
    <%= if @direction in [:asc, :asc_nulls_first, :asc_nulls_last] do %>
      <span {@opts[:symbol_attrs]}><%= @opts[:symbol_asc] %></span>
    <% end %>
    <%= if @direction in [:desc, :desc_nulls_first, :desc_nulls_last] do %>
      <span {@opts[:symbol_attrs]}><%= @opts[:symbol_desc] %></span>
    <% end %>
    <%= if is_nil(@direction) && !is_nil(@opts[:symbol_unsorted]) do %>
      <span {@opts[:symbol_attrs]}><%= @opts[:symbol_unsorted] %></span>
    <% end %>
    """
  end

  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true

  defp sort_link(assigns) do
    ~H"""
    <%= link sort_link_attrs(@field, @event, @target) do %>
      <%= @label %>
    <% end %>
    """
  end

  defp sort_link_attrs(field, event, target) do
    [phx_value_order: field, to: "#"]
    |> Misc.maybe_put(:phx_click, event)
    |> Misc.maybe_put(:phx_target, target)
  end

  defp order_index(%Flop{order_by: nil}, _), do: nil

  defp order_index(%Flop{order_by: order_by}, field) do
    Enum.find_index(order_by, &(&1 == field))
  end

  defp order_direction(_, nil), do: nil
  defp order_direction(nil, _), do: :asc
  defp order_direction(directions, index), do: Enum.at(directions, index)

  defp is_sortable?(nil, _), do: false
  defp is_sortable?(_, nil), do: true

  defp is_sortable?(field, module) do
    field in (module |> struct() |> Flop.Schema.sortable())
  end
end
