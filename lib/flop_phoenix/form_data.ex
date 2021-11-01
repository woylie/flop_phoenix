defimpl Phoenix.HTML.FormData, for: Flop.Meta do
  import Flop.Phoenix.Misc, only: [maybe_put: 3]

  def to_form(meta, opts) do
    {name, opts} = name_and_opts(meta, opts)
    {errors, opts} = Keyword.pop(opts, :errors, [])
    {hidden, opts} = Keyword.pop(opts, :hidden, [])
    {params, opts} = Keyword.pop(opts, :params, %{})
    id = Keyword.get(opts, :id) || name || "flop"

    %Phoenix.HTML.Form{
      data: meta.flop,
      errors: errors,
      hidden: hidden_inputs(meta.flop, hidden),
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
    {prepend, opts} = Keyword.pop(opts, :prepend, [])
    {append, opts} = Keyword.pop(opts, :append, [])
    {skip_hidden_op, opts} = Keyword.pop(opts, :skip_hidden_op, false)

    name = if form.name, do: form.name <> "[filters]", else: "filters"
    id = if id = id || form.id, do: to_string(id <> "_filters"), else: "filters"
    filters = if flop.filters == [], do: default, else: flop.filters
    filters = prepend ++ filters ++ append

    for {filter, index} <- Enum.with_index(filters) do
      index_string = Integer.to_string(index)

      hidden =
        if skip_hidden_op,
          do: [field: filter.field],
          else: [field: filter.field, op: filter.op]

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

  defp no_unsupported_options!(opts) do
    if Keyword.has_key?(opts, :hidden) do
      raise ArgumentError,
            ":hidden is not supported on inputs_for with Flop.Meta."
    end

    if Keyword.has_key?(opts, :as) do
      raise ArgumentError,
            ":as is not supported on inputs_for with Flop.Meta."
    end
  end

  defp name_and_opts(_meta, opts) do
    case Keyword.pop(opts, :as) do
      {nil, opts} -> {nil, opts}
      {name, opts} -> {to_string(name), opts}
    end
  end

  defp hidden_inputs(%Flop{} = flop, hidden) do
    hidden
    |> maybe_put(:order_by, flop.order_by)
    |> maybe_put(:order_directions, flop.order_directions)
    |> maybe_put(:page_size, flop.page_size)
    |> maybe_put(:limit, flop.limit)
    |> maybe_put(:first, flop.first)
    |> maybe_put(:last, flop.last)
  end

  def input_type(_meta, _form, :after), do: :text_input
  def input_type(_meta, _form, :before), do: :text_input
  def input_type(_meta, _form, :first), do: :number_input
  def input_type(_meta, _form, :last), do: :number_input
  def input_type(_meta, _form, :limit), do: :number_input
  def input_type(_meta, _form, :offset), do: :number_input
  def input_type(_meta, _form, :page), do: :number_input
  def input_type(_meta, _form, :page_size), do: :number_input
  def input_type(_meta, _form, _field), do: :text_input

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
