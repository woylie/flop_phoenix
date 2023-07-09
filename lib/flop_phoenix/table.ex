defmodule Flop.Phoenix.Table do
  @moduledoc false

  use Phoenix.Component

  alias Flop.Phoenix.Misc
  alias Phoenix.HTML
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
      no_results_content: HTML.Tag.content_tag(:p, do: "No results."),
      symbol_asc: "▴",
      symbol_attrs: [class: "order-direction"],
      symbol_desc: "▾",
      symbol_unsorted: nil,
      table_attrs: [],
      tbody_attrs: [],
      tbody_td_attrs: [],
      tbody_tr_attrs: [],
      thead_attrs: [],
      th_wrapper_attrs: [],
      thead_th_attrs: [],
      thead_tr_attrs: []
    ]
  end

  @doc """
  Deep merges the given options into the default options.
  """
  @spec init_assigns(map) :: map
  def init_assigns(%{meta: meta} = assigns) do
    assigns = assign(assigns, :opts, merge_opts(assigns[:opts] || []))
    Misc.validate_path_or_event!(assigns, @path_event_error_msg)

    assign_new(assigns, :id, fn ->
      case meta.schema do
        nil ->
          "paginated_table"

        module ->
          module_name =
            module |> Module.split() |> List.last() |> Macro.underscore()

          module_name <> "_table"
      end
    end)
  end

  defp merge_opts(opts) do
    default_opts()
    |> Misc.deep_merge(Misc.get_global_opts(:table))
    |> Misc.deep_merge(opts)
  end

  attr :id, :string, required: true
  attr :meta, Flop.Meta, required: true
  attr :path, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :caption, :string, required: true
  attr :opts, :any, required: true
  attr :col, :any, required: true
  attr :items, :list, required: true
  attr :foot, :any, required: true
  attr :row_id, :any, default: nil
  attr :row_click, JS, default: nil
  attr :row_item, :any, required: true
  attr :action, :any, required: true

  def render(assigns) do
    assigns =
      with %{items: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table {@opts[:table_attrs]}>
      <caption :if={@caption}><%= @caption %></caption>
      <colgroup :if={
        Enum.any?(@col, & &1[:col_style]) or Enum.any?(@action, & &1[:col_style])
      }>
        <%= for col <- @col do %>
          <col :if={show_column?(col)} style={col[:col_style]} />
        <% end %>
        <%= for action <- @action do %>
          <col :if={show_column?(action)} style={action[:col_style]} />
        <% end %>
      </colgroup>
      <thead {@opts[:thead_attrs]}>
        <tr {@opts[:thead_tr_attrs]}>
          <%= for col <- @col do %>
            <.header_column
              :if={show_column?(col)}
              event={@event}
              field={col[:field]}
              label={col[:label]}
              meta={@meta}
              opts={@opts}
              path={@path}
              target={@target}
            />
          <% end %>
          <%= for action <- @action do %>
            <.header_column
              :if={show_column?(action)}
              event={@event}
              field={nil}
              label={action[:label]}
              meta={@meta}
              opts={@opts}
              path={nil}
              target={@event}
            />
          <% end %>
        </tr>
      </thead>
      <tbody
        id={@id}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @items) && "stream"}
        {@opts[:tbody_attrs]}
      >
        <tr
          :for={item <- @items}
          id={@row_id && @row_id.(item)}
          {maybe_invoke_options_callback(@opts[:tbody_tr_attrs], item)}
        >
          <%= for col <- @col do %>
            <td
              :if={show_column?(col)}
              {@opts[:tbody_td_attrs]}
              {maybe_invoke_options_callback(Map.get(col, :attrs, []), item)}
              phx-click={@row_click && @row_click.(item)}
            >
              <%= render_slot(col, @row_item.(item)) %>
            </td>
          <% end %>
          <td
            :for={action <- @action}
            {@opts[:tbody_td_attrs]}
            {Map.get(action, :attrs, [])}
          >
            <%= render_slot(action, @row_item.(item)) %>
          </td>
        </tr>
      </tbody>
      <tfoot :if={@foot != []}><%= render_slot(@foot) %></tfoot>
    </table>
    """
  end

  defp maybe_invoke_options_callback(option, item) when is_function(option),
    do: option.(item)

  defp maybe_invoke_options_callback(option, _item), do: option

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
    direction = order_direction(assigns.meta.flop, assigns.field)
    assigns = assign(assigns, :order_direction, direction)

    ~H"""
    <%= if sortable?(@field, @meta.schema) do %>
      <th {@opts[:thead_th_attrs]} aria-sort={aria_sort(@order_direction)}>
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

  defp aria_sort(:desc), do: "descending"
  defp aria_sort(:desc_nulls_last), do: "descending"
  defp aria_sort(:desc_nulls_first), do: "descending"
  defp aria_sort(:asc), do: "ascending"
  defp aria_sort(:asc_nulls_last), do: "ascending"
  defp aria_sort(:asc_nulls_first), do: "ascending"
  defp aria_sort(_), do: nil

  attr :direction, :atom, required: true
  attr :opts, :list, required: true

  defp arrow(assigns) do
    ~H"""
    <span
      :if={@direction in [:asc, :asc_nulls_first, :asc_nulls_last]}
      {@opts[:symbol_attrs]}
    >
      <%= @opts[:symbol_asc] %>
    </span>
    <span
      :if={@direction in [:desc, :desc_nulls_first, :desc_nulls_last]}
      {@opts[:symbol_attrs]}
    >
      <%= @opts[:symbol_desc] %>
    </span>
    <span
      :if={is_nil(@direction) && !is_nil(@opts[:symbol_unsorted])}
      {@opts[:symbol_attrs]}
    >
      <%= @opts[:symbol_unsorted] %>
    </span>
    """
  end

  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true

  defp sort_link(assigns) do
    ~H"""
    <.link phx-click={@event} phx-target={@target} phx-value-order={@field}>
      <%= @label %>
    </.link>
    """
  end

  defp order_direction(
         %Flop{order_by: [field | _], order_directions: [direction | _]},
         field
       ) do
    direction
  end

  defp order_direction(%Flop{}, _), do: nil

  defp sortable?(nil, _), do: false
  defp sortable?(_, nil), do: true

  defp sortable?(field, module) do
    field in (module |> struct() |> Flop.Schema.sortable())
  end
end
