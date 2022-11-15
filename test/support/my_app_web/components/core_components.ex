defmodule MyAppWeb.CoreComponents do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  use Phoenix.Component

  import Flop.Phoenix
  import Phoenix.HTML.Form

  attr :meta, Flop.Meta, required: true
  attr :fields, :list, required: true

  def filter_form(assigns) do
    rest = assigns_to_attributes(assigns, [:meta, :fields])
    assigns = assign(assigns, :rest, rest)

    ~H"""
    <.form :let={f} for={@meta}>
      <.filter_fields :let={i} form={f} fields={@fields} {@rest}>
        <.input
          id={i.id}
          name={i.name}
          label={i.label}
          type={i.type}
          value={i.value}
          field={{i.form, i.field}}
          {i.rest}
        />
      </.filter_fields>
    </.form>
    """
  end

  @doc """
  Input component derived from Phoenix.
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil
  attr :type, :string, default: "text"
  attr :value, :any
  attr :field, :any, doc: "e.g. {f, :email}"
  attr :errors, :list
  attr :rest, :global
  slot :inner_block

  slot :option, doc: "select input options" do
    attr :value, :any
  end

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> input_name(f, field) end)
    |> assign_new(:id, fn -> input_id(f, field) end)
    |> assign_new(:value, fn -> input_value(f, field) end)
    |> assign(:errors, f.errors)
    |> input()
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id}><%= @label %></label>
      <input type={@type} name={@name} id={@id} value={@value} {@rest} />
      <.error :for={msg <- @errors} message={msg} />
    </div>
    """
  end

  attr :message, :string, required: true

  def error(assigns) do
    ~H"""
    <p class="error"><%= @message %></p>
    """
  end

  def pagination_opts do
    [pagination_list_attrs: [class: "pagination-links"]]
  end

  def table_opts do
    [table_attrs: [class: "sortable-table"]]
  end
end
