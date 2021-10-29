defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  alias Flop.Phoenix.Misc

  @spec default_opts() :: [Flop.Phoenix.table_option()]
  def default_opts do
    [
      container: false,
      container_attrs: [class: "table-container"],
      no_results_content: content_tag(:p, do: "No results."),
      symbol_asc: "▴",
      symbol_attrs: [class: "order-direction"],
      symbol_desc: "▾",
      table_attrs: [],
      tbody_td_attrs: [],
      tbody_tr_attrs: [],
      tfoot_td_attrs: [],
      tfoot_tr_attrs: [],
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
      |> assign_new(:event, fn -> nil end)
      |> assign_new(:footer, fn -> nil end)
      |> assign_new(:for, fn -> nil end)
      |> assign_new(:path_helper, fn -> nil end)
      |> assign_new(:path_helper_args, fn -> nil end)
      |> assign_new(:row_opts, fn -> [] end)
      |> assign_new(:target, fn -> nil end)
      |> assign(:opts, merge_opts(assigns[:opts] || []))

    if (assigns.path_helper && assigns.path_helper_args) || assigns.event do
      assigns
    else
      raise """
      Flop.Phoenix.table requires either the `path_helper` and
      `path_helper_args` assigns or the `event` assign to be set.

      ## Example

          <Flop.Phoenix.table
            items={@pets}
            meta={@meta}
            path_helper={&Routes.pet_path/3}
            path_helper_args={[@socket, :index]}
            headers={[{"Name", :name}, {"Age", :age}]}
          />

      or

          <Flop.Phoenix.table
            items={@pets}
            meta={@meta}
            event="sort-table"
            headers={[{"Name", :name}, {"Age", :age}]}
          />
      """
    end
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:table))
    |> Misc.deep_merge(opts)
  end

  def render(assigns) do
    ~H"""
    <table {@opts[:table_attrs]}>
      <thead>
        <tr {@opts[:thead_tr_attrs]}>
          <%= for col <- @col do %>
            <.header_column
              event={@event}
              field={col[:field]}
              flop={@meta.flop}
              for={@for}
              label={col.label}
              opts={@opts}
              path_helper={@path_helper}
              path_helper_args={@path_helper_args}
              target={@target}
            />
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr {@opts[:tbody_tr_attrs]}>
            <%= for col <- @col do %>
              <td {@opts[:tbody_td_attrs]}><%= render_slot(col, item) %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
      <%= if @footer do %>
        <tfoot>
          <%= render_slot(@footer) %>
        </tfoot>
      <% end %>
    </table>
    """
  end

  #

  defp header_column(assigns) do
    index = order_index(assigns.flop, assigns.field)
    direction = order_direction(assigns.flop.order_directions, index)

    assigns =
      assigns
      |> assign(:order_index, index)
      |> assign(:order_direction, direction)

    ~H"""
    <%= if is_sortable?(@field, @for) do %>
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
            <%= live_patch(@label,
              to:
                Flop.Phoenix.build_path(
                  @path_helper,
                  @path_helper_args,
                  Flop.push_order(@flop, @field),
                  for: @for
                )
            )
            %>
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

  defp arrow(assigns) do
    ~H"""
    <%= if @direction in [:asc, :asc_nulls_first, :asc_nulls_last] do %>
      <span {@opts[:symbol_attrs]}><%= @opts[:symbol_asc] %></span>
    <% end %>
    <%= if @direction in [:desc, :desc_nulls_first, :desc_nulls_last] do %>
      <span {@opts[:symbol_attrs]}><%= @opts[:symbol_desc] %></span>
    <% end %>
    """
  end

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
