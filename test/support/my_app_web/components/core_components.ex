defmodule MyAppWeb.CoreComponents do
  @moduledoc """
  Defines opts provider functions reference in the config for tests.
  """

  use Phoenix.Component

  import Flop.Phoenix

  attr :meta, Flop.Meta, required: true
  attr :fields, :list, required: true
  attr :rest, :global

  def filter_form(%{meta: meta} = assigns) do
    assigns = assign(assigns, :form, to_form(meta))

    ~H"""
    <.form for={@form}>
      <.filter_fields :let={i} form={@form} fields={@fields} {@rest}>
        <.input field={i.field} label={i.label} type={i.type} {i.rest} />
      </.filter_fields>
    </.form>
    """
  end

  @doc """
  Input component derived from Phoenix.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number
      password range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField

  attr :errors, :list, default: []
  attr :checked, :boolean
  attr :prompt, :string, default: nil

  attr :options, :list

  attr :multiple, :boolean, default: false

  attr :rest, :global,
    include: ~w(autocomplete cols disabled form max maxlength min minlength
           pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, field.errors)
    |> assign_new(:name, fn ->
      if assigns.multiple, do: field.name <> "[]", else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{field: nil} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <label for={@id}><%= @label %></label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
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
