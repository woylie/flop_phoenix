defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  alias Flop.Phoenix.Misc

  require Logger

  @example """
  ## Example

      <Flop.Phoenix.table
        items={@pets}
        meta={@meta}
        path_helper={{Routes, :pet_path, [@socket, :index]}}
      >
        <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
      </Flop.Phoenix.table>
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
    assigns = assign(assigns, :opts, merge_opts(assigns[:opts]))
    validate_assigns!(assigns)
    assigns
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:table))
    |> Misc.deep_merge(opts)
  end

  attr :meta, Flop.Meta, required: true
  attr :path_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :caption, :string, required: true
  attr :opts, :any, required: true
  attr :col, :any, required: true
  attr :items, :list, required: true
  attr :foot, :any, required: true

  def render(assigns) do
    ~H"""
    <table {@opts[:table_attrs]}>
      <%= if @caption do %>
        <caption><%= @caption %></caption>
      <% end %>
      <%= if Enum.any?(@col, & &1[:col_style]) do %>
        <colgroup>
          <%= for col <- @col do %>
            <col style={col[:col_style]} />
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
                path_helper={@path_helper}
                target={@target}
              />
            <% end %>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr {@opts[:tbody_tr_attrs]}>
            <%= for col <- @col do %>
              <%= if show_column?(col) do %>
                <td
                  {@opts[:tbody_td_attrs]}
                  {
                    assigns_to_attributes(
                      col,
                      [:col_style, :field, :hide, :label, :show]
                    )
                  }
                >
                  <%= render_slot(col, item) %>
                </td>
              <% end %>
            <% end %>
          </tr>
        <% end %>
      </tbody>
      <%= if @foot do %>
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
  attr :path_helper, :any, required: true
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
              build_path(
                @path_helper,
                Flop.push_order(@meta.flop, @field),
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

  defp build_path(path_helper, params, opts) do
    Flop.Phoenix.build_path(path_helper, params, opts)
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

  defp validate_assigns!(assigns) do
    validate_col!(assigns)
    validate_items!(assigns)
    validate_meta!(assigns)
    validate_path_helper_or_event!(assigns)
  end

  defp validate_col!(assigns) do
    unless assigns[:col] do
      raise ArgumentError, """
      the :col slot is required when rendering a table

      Add at least one <:col> tag with a label.

      #{@example}
      """
    end
  end

  defp validate_items!(assigns) do
    unless assigns[:items] do
      raise ArgumentError, """
      the :items option is required when rendering a table

      The value is the query result list. Each item in the list results in one
      table row.

      #{@example}
      """
    end
  end

  defp validate_meta!(assigns) do
    unless assigns[:meta] do
      raise ArgumentError, """
      the :meta option is required when rendering a table

      The value is the Flop.Meta struct returned by the query function.

      #{@example}
      """
    end
  end

  defp validate_path_helper_or_event!(%{
         path_helper: path_helper,
         event: event
       }) do
    case {path_helper, event} do
      {{module, function, args}, nil}
      when is_atom(module) and is_atom(function) and is_list(args) ->
        :ok

      {{function, args}, nil} when is_function(function) and is_list(args) ->
        :ok

      {nil, event} when is_binary(event) ->
        :ok

      _ ->
        raise ArgumentError, """
        the :path_helper or :event option is required when rendering a table

        The :path_helper value can be a {module, function_name, args} tuple or a
        {function, args} tuple.

        The :event value needs to be a string.

        ## Examples

            <Flop.Phoenix.table
              items={@pets}
              meta={@meta}
              path_helper={{Routes, :pet_path, [@socket, :index]}}
            >

        or

            <Flop.Phoenix.table
              items={@pets}
              meta={@meta}
              path_helper={{&Routes.pet_path/3, [@socket, :index]}}
            >

        or

            <Flop.Phoenix.table
              items={@pets}
              meta={@meta}
              event="sort-table"
            >
        """
    end
  end
end
