defmodule Flop.Phoenix.Filter do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  @default_using_by_type %{
    integer: :number_input,
    float: :number_input,
    decimal: :number_input,
    boolean: :checkbox,
    date: :date_select,
    time: :time_select,
    time_usec: :time_select,
    naive_datetime: :datetime_select,
    naive_datetime_usec: :datetime_select,
    utc_datetime: :datetime_select,
    utc_datetime_usrc: :datetime_select
  }

  @spec init_inputs_for_assigns(map) :: map
  def init_inputs_for_assigns(assigns) do
    expand_fields(assigns)
  end

  defp expand_fields(%{fields: fields, for: schema} = assigns) do
    fields = Enum.map(fields, &expand_field(&1, schema))

    assign(assigns, :fields, fields)
  end

  defp expand_fields(%{for: schema} = assigns) do
    filterable_fields =
      schema
      |> struct()
      |> Flop.Schema.filterable()

    assigns
    |> assign(:fields, filterable_fields)
    |> expand_fields()
  end

  defp expand_field(field, schema) when is_atom(field) do
    expand_field({field, []}, schema)
  end

  defp expand_field({field, field_opts}, schema)
       when is_atom(field) and is_list(field_opts) do
    field_type = schema.__schema__(:type, field)

    field_opts =
      field_opts
      |> Keyword.put_new(:label, field)
      |> Keyword.put_new(:op, :==)
      |> Keyword.put_new_lazy(:using, fn ->
        Map.get(@default_using_by_type, field_type, :text_input)
      end)

    {field, field_opts}
  end

  @spec inputs_for_opts(Flop.Meta.t(), [map]) :: keyword
  def inputs_for_opts(meta, fields) do
    default =
      Enum.map(fields, fn {field, field_opts} ->
        %{
          field: field,
          op: from_current_filter(meta, field, :op) || default_op(field_opts),
          value: from_current_filter(meta, field, :value)
        }
      end)

    [as: :filters, default: default]
  end

  defp from_current_filter(meta, field, key) do
    if filter = Enum.find(meta.flop.filters, &(&1.field == field)) do
      Map.fetch!(filter, key)
    end
  end

  defp default_op(field_opts) do
    case Keyword.fetch!(field_opts, :op) do
      [op] -> op
      [_ | _] -> nil
      op -> op
    end
  end

  @spec field_opts(Phoenix.HTML.Form.t(), [map]) :: map
  def field_opts(form, fields) do
    field = input_value(form, :field)

    fields
    |> Keyword.fetch!(field)
    |> Map.new()
  end

  @spec render_input(map) :: Phoenix.LiveView.Rendered.t()
  def render_input(assigns) do
    ~H"""
    <div>
      <%= hidden_input @form, :field %>

      <%= case @op do %>
        <% op when is_list(op) -> %>
          <%= select @form, :op, @op %>

        <% _op -> %>
          <%= hidden_input @form, :op %>
      <% end %>

      <%= label @form, :value, @label %>
      <%= input_helper_from_using(@using).(@form, :value, []) %>
    </div>
    """
  end

  defp input_helper_from_using(using) do
    cond do
      is_function(using, 3) ->
        using

      is_atom(using) && function_exported?(Phoenix.HTML.Form, using, 3) ->
        Function.capture(Phoenix.HTML.Form, using, 3)

      true ->
        raise("""
        unknown using option: #{inspect(using)}

        TODO
        """)
    end
  end
end
