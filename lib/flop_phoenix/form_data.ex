defimpl Phoenix.HTML.FormData, for: Flop.Meta do
  alias Flop.Filter
  alias Flop.Meta
  alias Flop.Phoenix.Misc

  def to_form(meta, opts) do
    {name, opts} = name_and_opts(meta, opts)
    {errors, opts} = Keyword.pop(opts, :errors, [])
    {hidden, opts} = Keyword.pop(opts, :hidden, [])
    {params, opts} = Keyword.pop(opts, :params, %{})
    id = Keyword.get(opts, :id) || name || "flop"

    %Phoenix.HTML.Form{
      data: meta.flop,
      errors: errors,
      hidden: hidden_inputs(meta, hidden),
      id: id,
      impl: __MODULE__,
      name: name,
      options: opts,
      params: params,
      source: meta
    }
  end

  def to_form(
        meta,
        %{data: %Flop{} = flop} = form,
        :filters,
        opts
      ) do
    no_unsupported_options!(opts)

    {id, opts} = Keyword.pop(opts, :id)
    {default, opts} = Keyword.pop(opts, :default, [])
    {fields, opts} = Keyword.pop(opts, :fields)
    {skip_hidden_op, opts} = Keyword.pop(opts, :skip_hidden_op, false)

    name = if form.name, do: form.name <> "[filters]", else: "filters"
    id = if id = id || form.id, do: to_string(id <> "_filters"), else: "filters"

    filters =
      flop
      |> filters_for(fields, default)
      |> reject_unfilterable(meta.schema)

    for {filter, index} <- Enum.with_index(filters) do
      index_string = Integer.to_string(index)

      hidden =
        if skip_hidden_op,
          do: [field: filter.field],
          else: Misc.maybe_put([field: filter.field], :op, filter.op, :==)

      %Phoenix.HTML.Form{
        source: meta,
        impl: __MODULE__,
        index: index,
        id: id <> "_" <> index_string,
        name: name <> "[" <> index_string <> "]",
        data: filter,
        params: %{},
        hidden: hidden,
        options: opts
      }
    end
  end

  def to_form(_meta, _form, field, _opts) do
    raise ArgumentError,
          "Only :filters is supported on " <>
            "inputs_for with Flop.Meta, got: #{inspect(field)}."
  end

  defp filters_for(%Flop{filters: []}, nil, default), do: default
  defp filters_for(%Flop{filters: filters}, nil, _), do: filters

  defp filters_for(%Flop{filters: filters}, fields, _) when is_list(fields) do
    fields
    |> Enum.reduce([], &filter_reducer(&1, &2, filters))
    |> Enum.reverse()
  end

  defp filter_reducer({field, opts}, acc, filters)
       when is_atom(field) and is_list(opts) do
    op = opts[:op] || :==
    default = opts[:default]

    if filter = Enum.find(filters, &(&1.field == field && &1.op == op)) do
      [filter | acc]
    else
      [%Filter{field: field, op: op, value: default} | acc]
    end
  end

  defp filter_reducer(field, acc, filters) when is_atom(field) do
    filter_reducer({field, []}, acc, filters)
  end

  defp reject_unfilterable(filters, nil), do: filters

  defp reject_unfilterable(filters, schema) do
    filterable = schema |> struct() |> Flop.Schema.filterable()
    Enum.reject(filters, &(&1.field not in filterable))
  end

  defp no_unsupported_options!(opts) do
    for key <- [:append, :as, :hidden, :prepend] do
      if Keyword.has_key?(opts, key) do
        raise ArgumentError,
              "#{inspect(key)} is not supported on inputs_for with Flop.Meta."
      end
    end
  end

  defp name_and_opts(_meta, opts) do
    case Keyword.pop(opts, :as) do
      {nil, opts} -> {nil, opts}
      {name, opts} -> {to_string(name), opts}
    end
  end

  defp hidden_inputs(%Meta{flop: %Flop{} = flop, schema: schema}, hidden) do
    default_limit = Flop.get_option(:default_limit, for: schema)
    default_order = Flop.get_option(:default_order, for: schema)

    hidden
    |> Misc.maybe_put(:page_size, flop.page_size, default_limit)
    |> Misc.maybe_put(:limit, flop.limit, default_limit)
    |> Misc.maybe_put(:first, flop.first, default_limit)
    |> Misc.maybe_put(:last, flop.last, default_limit)
    |> Misc.maybe_put_order_params(flop, default_order)
  end

  def input_type(_meta, _form, :after), do: :text_input
  def input_type(_meta, _form, :before), do: :text_input
  def input_type(_meta, _form, :first), do: :number_input
  def input_type(_meta, _form, :last), do: :number_input
  def input_type(_meta, _form, :limit), do: :number_input
  def input_type(_meta, _form, :offset), do: :number_input
  def input_type(_meta, _form, :page), do: :number_input
  def input_type(_meta, _form, :page_size), do: :number_input

  def input_type(
        _meta,
        %{data: %Filter{field: field}, source: %{schema: schema}},
        :value
      )
      when not is_nil(schema) do
    :type |> schema.__schema__(field) |> input_type_for_ecto_type()
  end

  def input_type(_meta, _form, _field), do: :text_input

  defp input_type_for_ecto_type(:boolean), do: :checkbox
  defp input_type_for_ecto_type(:date), do: :date_select
  defp input_type_for_ecto_type(:integer), do: :number_input
  defp input_type_for_ecto_type(:naive_datetime), do: :datetime_select
  defp input_type_for_ecto_type(:naive_datetime_usec), do: :datetime_select
  defp input_type_for_ecto_type(:time), do: :time_select
  defp input_type_for_ecto_type(:time_usec), do: :time_select
  defp input_type_for_ecto_type(:utc_datetime), do: :datetime_select
  defp input_type_for_ecto_type(:utc_datetime_usec), do: :datetime_select
  defp input_type_for_ecto_type(_), do: :text_input

  def input_validations(_meta, _form, :after), do: [maxlength: 100]
  def input_validations(_meta, _form, :before), do: [maxlength: 100]
  def input_validations(_meta, _form, :offset), do: [min: 0]
  def input_validations(_meta, _form, :page), do: [min: 1]

  def input_validations(_meta, %{source: %Flop.Meta{schema: nil}}, field)
      when field in [:first, :last, :limit, :page_size],
      do: [min: 1]

  def input_validations(_meta, %{source: %Flop.Meta{schema: schema}}, field)
      when field in [:first, :last, :limit, :page_size] do
    if max_limit = Flop.get_option(:max_limit, for: schema) do
      [min: 1, max: max_limit]
    else
      [min: 1]
    end
  end

  def input_validations(
        _meta,
        %{data: %Filter{field: field}, source: %{schema: schema}},
        :value
      )
      when not is_nil(schema) do
    case :type |> schema.__schema__(field) |> input_type_for_ecto_type() do
      :text_input -> [maxlength: 100]
      _ -> []
    end
  end

  def input_validations(_meta, _form, _field), do: []

  def input_value(_meta, %{data: data, params: params}, field)
      when is_atom(field) do
    key = Atom.to_string(field)

    case params do
      %{^key => value} -> value
      %{} -> Map.get(data, field)
    end
  end

  def input_value(_meta, _form, field) do
    raise ArgumentError, "expected field to be an atom, got: #{inspect(field)}"
  end
end
