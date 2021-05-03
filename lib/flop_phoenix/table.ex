defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  def render(assigns) do
    ~L"""
    <table<%= if @opts[:table_class] do %> class="<%= @opts[:table_class] %>"<% end %>>
      <thead>
        <tr>
          <%= for header <- @headers do %>
            <%= header(header, @meta, @path_helper, @path_helper_args, @opts) %>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr>
            <%= for column <- @row_func.(item, @opts) do %>
              <td><%= column %></td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp header(
         {value, field},
         %Flop.Meta{flop: flop},
         path_helper,
         path_helper_args,
         opts
       ) do
    assigns = %{
      __changed__: nil,
      field: field,
      flop: flop,
      opts: opts,
      path_helper: path_helper,
      path_helper_args: path_helper_args,
      value: value
    }

    ~L"""
    <th>
      <%= if is_sortable?(field, opts[:for]) do %>
        <%= live_patch(@value,
              to:
                Flop.Phoenix.build_path(
                  @path_helper,
                  @path_helper_args,
                  Flop.push_order(@flop, @field)
                )
            )
        %>
        <span class="<%= @opts[:symbol_class] || "order-direction" %>">
          <%= @flop |> current_direction(@field) |> render_arrow(@opts) %>
        </span>
      <% else %>
        <th><%= @value %></th>
      <% end %>
    </th>
    """
  end

  defp header(value, _, _, _, _) do
    assigns = %{__changed__: nil, value: value}

    ~L"""
    <th><%= @value %></th>
    """
  end

  defp is_sortable?(_, nil), do: true

  defp is_sortable?(field, module),
    do: field in (module |> struct() |> Flop.Schema.sortable())

  defp render_arrow(nil, _), do: ""

  defp render_arrow(direction, opts) do
    assigns = %{__changed__: nil, direction: direction, opts: opts}

    ~L"""
    <span class="<%= @opts[:symbol_class] || "order-direction" %>"><%=
      if @direction in [:asc, :asc_nulls_first, :asc_nulls_last] do
        Keyword.get(@opts, :symbol_asc, "▴")
      else
        Keyword.get(@opts, :symbol_desc, "▾")
      end
    %></span>
    """
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
end
