defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  def render(assigns) do
    ~L"""
    <%= content_tag :table, @opts[:table_attrs] do %>
      <thead><%=
        content_tag :tr, @opts[:thead_tr_attrs] do %><%=
          for header <- @headers do %><%=
            header(header, @meta, @path_helper, @path_helper_args, @opts)
          %><% end %>
        <% end %>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <%= content_tag :tr, @opts[:tbody_tr_attrs] do %><%=
            for column <- @row_func.(item, @opts) do %><%=
              content_tag :td, @opts[:tbody_td_attrs] do %><%= column %><% end %>
            <% end %>
          <% end %>
        <% end %>
      </tbody>
    <% end %>
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
    <%= content_tag :th, @opts[:thead_th_attrs] do %>
      <%= if is_sortable?(field, opts[:for]) do %>
        <%= content_tag :span, @opts[:th_wrapper_attrs] do %>
          <%= live_patch(@value,
                to:
                  Flop.Phoenix.build_path(
                    @path_helper,
                    @path_helper_args,
                    Flop.push_order(@flop, @field),
                    @opts
                  )
              )
          %>
          <%= @flop |> current_direction(@field) |> render_arrow(@opts) %>
        <% end %>
      <% else %><%= @value %><% end %>
    <% end %>
    """
  end

  defp header(value, _, _, _, opts) do
    assigns = %{__changed__: nil, opts: opts, value: value}

    ~L"""
    <%= content_tag :th, @opts[:thead_th_attrs] do %><%= @value %><% end %>
    """
  end

  defp is_sortable?(_, nil), do: true

  defp is_sortable?(field, module),
    do: field in (module |> struct() |> Flop.Schema.sortable())

  defp render_arrow(nil, _), do: ""

  defp render_arrow(direction, opts) do
    assigns = %{__changed__: nil, direction: direction, opts: opts}

    ~L"""
    <%= content_tag :span, @opts[:symbol_attrs] do %><%=
      if @direction in [:asc, :asc_nulls_first, :asc_nulls_last] do
        @opts[:symbol_asc]
      else
        @opts[:symbol_desc]
      end
    %><% end %>
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
