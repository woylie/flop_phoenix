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
      th_wrapper_attrs: [],
      thead_th_attrs: [],
      thead_tr_attrs: []
    ]
  end

  @spec init_opts([Flop.Phoenix.table_option()]) :: [
          Flop.Phoenix.table_option()
        ]
  def init_opts(opts) do
    Misc.deep_merge(default_opts(), opts)
  end

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

  defp header({:safe, value}, _, _, _, opts) do
    not_sortable_header(%{opts: opts, value: {:safe, value}})
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

    if is_sortable?(field, opts[:for]) do
      ~L"""
      <%= content_tag :th, @opts[:thead_th_attrs] do %>
        <%= content_tag :span, @opts[:th_wrapper_attrs] do %>
          <%= if opts[:event] do %>
            <%= sort_link(%{field: @field, opts: @opts, value: @value}) %>
          <% else %>
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
          <% end %>
          <%= arrow(%{direction: current_direction(@flop, @field), opts: @opts}) %>
        <% end %>
      <% end %>
      """
    else
      not_sortable_header(%{opts: opts, value: value})
    end
  end

  defp header(value, _, _, _, opts) do
    not_sortable_header(%{opts: opts, value: value})
  end

  defp not_sortable_header(assigns) do
    ~H"""
    <th {@opts[:thead_th_attrs]}><%= @value %></th>
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
    <%= link sort_link_attrs(@field, @opts) do %><%= @value %><% end %>
    """
  end

  defp sort_link_attrs(field, opts) do
    []
    |> Keyword.put(:phx_value_order, field)
    |> Keyword.put(:to, "#")
    |> Misc.maybe_put(:phx_click, opts[:event])
    |> Misc.maybe_put(:phx_target, opts[:target])
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

  defp is_sortable?(_, nil), do: true

  defp is_sortable?(field, module) do
    field in (module |> struct() |> Flop.Schema.sortable())
  end
end
