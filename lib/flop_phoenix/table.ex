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
      |> assign(:opts, Misc.deep_merge(default_opts(), assigns[:opts] || []))

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
            row_func={fn pet, _opts -> [pet.name, pet.age] end}
          />

      or

          <Flop.Phoenix.table
            items={@pets}
            meta={@meta}
            event="sort-table"
            headers={[{"Name", :name}, {"Age", :age}]}
            row_func={fn pet, _opts -> [pet.name, pet.age] end}
          />
      """
    end
  end

  def render(assigns) do
    ~H"""
    <table {@opts[:table_attrs]}>
      <thead>
        <tr {@opts[:thead_tr_attrs]}><%=
          for header <- @headers do %>
            <.header_column
              event={@event}
              flop={@meta.flop}
              for={@for}
              header={header}
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
            <%= for column <- @row_func.(item, @row_opts) do %>
              <td {@opts[:tbody_td_attrs]}><%= column %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
      <%= if @footer do %>
        <tfoot>
          <tr {@opts[:tfoot_tr_attrs]}>
            <%= for content <- @footer do %>
              <td {@opts[:tfoot_td_attrs]}><%= content %></td>
            <% end %>
          </tr>
        </tfoot>
      <% end %>
    </table>
    """
  end

  defp header_column(assigns) do
    assigns =
      assigns
      |> assign(:field, header_field(assigns.header))
      |> assign(:value, header_value(assigns.header))

    ~H"""
    <%= if is_sortable?(@field, @for) do %>
      <th {@opts[:thead_th_attrs]}>
        <span {@opts[:th_wrapper_attrs]}>
          <%= if @event do %>
            <.sort_link
              field={@field}
              event={@event}
              target={@target}
              value={@value}
            />
          <% else %>
            <%= live_patch(@value,
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
          <.arrow direction={current_direction(@flop, @field)} opts={@opts} />
        </span>
      </th>
    <% else %>
      <th {@opts[:thead_th_attrs]}><%= @value %></th>
    <% end %>
    """
  end

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
      <%= @value %>
    <% end %>
    """
  end

  defp sort_link_attrs(field, event, target) do
    [phx_value_order: field, to: "#"]
    |> Misc.maybe_put(:phx_click, event)
    |> Misc.maybe_put(:phx_target, target)
  end

  defp current_direction(%Flop{order_by: nil}, _), do: nil

  defp current_direction(
         %Flop{order_by: order_by, order_directions: directions},
         field
       ) do
    order_by
    |> Enum.find_index(&(&1 == field))
    |> get_order_direction(directions)
  end

  defp get_order_direction(nil, _), do: nil
  defp get_order_direction(_, nil), do: :asc
  defp get_order_direction(index, directions), do: Enum.at(directions, index)

  defp is_sortable?(nil, _), do: false
  defp is_sortable?(_, nil), do: true

  defp is_sortable?(field, module) do
    field in (module |> struct() |> Flop.Schema.sortable())
  end

  defp header_field({:safe, _}), do: nil
  defp header_field({_value, field}), do: field
  defp header_field(_value), do: nil

  defp header_value({:safe, _} = value), do: value
  defp header_value({value, _field}), do: value
  defp header_value(value), do: value
end
