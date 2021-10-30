defmodule Flop.Phoenix.Filter do
  @moduledoc false

  use Phoenix.Component
  use Phoenix.HTML

  @spec init_inputs_for_assigns(map) :: map
  def init_inputs_for_assigns(assigns) do
    assigns
    |> expand_fields()
    |> assign_default()
    |> assign_input_assigns()
  end

  defp expand_fields(%{fields: fields, for: schema} = assigns) do
    fields =
      fields
      |> Enum.map(&expand_field(&1, schema))
      |> Map.new()

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
      |> Keyword.put_new_lazy(:using, fn -> default_input(field_type) end)
      |> Keyword.put_new_lazy(:default_op, fn -> default_op(field_type) end)

    {field, field_opts}
  end

  defp default_input(type) when type in [:id, :binary_id, :string, :binary],
    do: :text_input

  defp default_input(type) when type in [:integer, :float, :decimal],
    do: :number_input

  defp default_input(:boolean), do: :checkbox
  defp default_input(:date), do: :date_input
  defp default_input(type) when type in [:time, :time_usec], do: :time_input

  defp default_input(type)
       when type in [
              :naive_datetime,
              :naive_datetime_usec,
              :utc_datetime,
              :utc_datetime_usec
            ],
       do: :datetime_input

  defp default_input(type),
    do: raise("unsupported filter field type '#{inspect(type)}'")

  defp default_op(type)
       when type in [
              :id,
              :binary_id,
              :integer,
              :float,
              :decimal,
              :boolean,
              :date,
              :time,
              :time_usec,
              :naive_datetime,
              :naive_datetime_sec,
              :utc_datetime,
              :utc_datetime_usec
            ],
       do: :==

  defp default_op(type) when type in [:string, :binary], do: :ilike

  defp default_op(type),
    do: raise("unsupported filter field type '#{inspect(type)}'")

  defp assign_default(%{fields: fields, meta: meta} = assigns) do
    default =
      Enum.map(fields, fn {field, field_opts} ->
        %{
          field: field,
          op: Keyword.fetch!(field_opts, :default_op),
          value: current_value(meta, field)
        }
      end)

    assign(assigns, :default, default)
  end

  defp current_value(meta, field) do
    if filter = Enum.find(meta.flop.filters, &(&1.field == field)) do
      filter.value
    end
  end

  defp assign_input_assigns(%{fields: fields} = assigns) do
    input_assigns =
      Map.new(fields, fn {field, field_opts} ->
        {field,
         field_opts
         |> Keyword.take([:label, :using, :op_selectable, :op_selectable_from])
         |> Map.new()}
      end)

    assign(assigns, :input_assigns, input_assigns)
  end

  @spec init_input_assigns(map) :: map
  def init_input_assigns(assigns) do
    assigns
    |> assign_input_helper()
    |> assign_new(:op_selectable, fn -> false end)
    |> assign_op_selectable_from()
  end

  defp assign_input_helper(%{using: using} = assigns) do
    assign(assigns, :input_helper, input_helper_from_using(using))
  end

  defp input_helper_from_using(using) do
    cond do
      is_function(using, 3) ->
        using

      is_atom(using) && function_exported?(Phoenix.HTML.Form, using, 3) ->
        Function.capture(Phoenix.HTML.Form, using, 3)

      true ->
        # TODO
        raise("unknown using #{using}")
    end
  end

  defp assign_op_selectable_from(%{op_selectable: false} = assigns), do: assigns

  defp assign_op_selectable_from(%{op_selectable_from: _list} = assigns),
    do: assigns

  defp assign_op_selectable_from(assigns) do
    assign(assigns, :op_selectable_from, default_op_selectable_from())
  end

  defp default_op_selectable_from do
    # TODO: For a sensible preselection we need the type again here.
    # But I tried to keep `filter_input` agnostic of the type (no `for` assign).
    # Overall it's a bit of a conflict between the `default` injection into `inputs_for` and the
    # desire to make such decisions (e.g. the "default op") closer to where it is used, i.e.
    # in `filter_input`... Not sure
    [
      :==,
      :!=,
      :=~,
      :empty,
      :not_empty,
      :<=,
      :<,
      :>=,
      :>,
      :in,
      :like,
      :like_and,
      :like_or,
      :ilike,
      :ilike_and,
      :ilike_or
    ]
  end
end
