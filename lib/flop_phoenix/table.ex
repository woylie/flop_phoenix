defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

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
    Keyword.merge(default_opts(), opts)
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
    not_sortable_header({:safe, value}, opts)
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
            <%= sort_link(@opts, @field, @value) %>
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
          <%= @flop |> current_direction(@field) |> render_arrow(@opts) %>
        <% end %>
      <% end %>
      """
    else
      not_sortable_header(value, opts)
    end
  end

  defp header(value, _, _, _, opts) do
    not_sortable_header(value, opts)
  end

  defp not_sortable_header(value, opts) do
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

  defp sort_link(opts, field, value) do
    attrs =
      Keyword.new()
      |> Keyword.put(:phx_click, opts[:event])
      |> Keyword.put(:phx_value_order, field)
      |> Keyword.put(:to, "#")
      |> maybe_put_target(opts[:live_target])

    assigns = %{__changed__: nil, value: value, attrs: attrs}

    ~L"""
      <%= link @attrs do %>
        <%= @value %>
      <% end %>
    """
  end

  defp maybe_put_target(attrs, nil), do: attrs

  defp maybe_put_target(attrs, live_target),
    do: Keyword.put(attrs, :phx_target, live_target)

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
