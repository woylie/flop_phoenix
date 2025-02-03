# Flop Phoenix

![CI](https://github.com/woylie/flop_phoenix/workflows/CI/badge.svg) [![Hex](https://img.shields.io/hexpm/v/flop_phoenix)](https://hex.pm/packages/flop_phoenix) [![Coverage Status](https://coveralls.io/repos/github/woylie/flop_phoenix/badge.svg)](https://coveralls.io/github/woylie/flop_phoenix)

Flop Phoenix provides Phoenix components for pagination, sortable tables, and
filter forms with [Flop](https://hex.pm/packages/flop) and
[Ecto](https://hex.pm/packages/ecto).

## Installation

Add `flop_phoenix` to your list of dependencies in the `mix.exs` of your Phoenix
application.

```elixir
def deps do
  [
    {:flop_phoenix, "~> 0.24.1"}
  ]
end
```

Next, set up your business logic following the
[Flop documentation](https://hex.pm/packages/flop).

## Usage

### Context

Define a context function that uses `Flop.validate_and_run/3` to perform a
list query. For example:

```elixir
defmodule MyApp.Pets do
  alias MyApp.Pet

  def list_pets(params) do
    Flop.validate_and_run(Pet, params, for: Pet, replace_invalid_params: true)
  end
end
```

Note the usage of the `replace_invalid_params` option, which lets Flop ignore
invalid parameters instead of returning an error.

### LiveView

In the LiveView module, fetch the data and assign it alongside the meta data to
the socket.

```elixir
defmodule MyAppWeb.PetLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Pets

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    # We set `replace_invalid_params` to `true` in the context function, so we
    # should never get an error. If you don't set the option, Flop will return
    # an error tuple with a `Flop.Meta` struct which includes the validation
    # errors.
    {:ok, {pets, meta}} = Pets.list_pets(params)
  end
end
```

If you prefer the `Flop.Phoenix` components not to reflect pagination, sorting,
and filtering parameters in the URL, fetch and assign the data in the
`c:Phoenix.LiveView.handle_event/3` callback instead. You need to pass a
`Phoenix.LiveView.JS` command as an attribute to the components in that case.

### Controller

For non-LiveView ("dead") views, pass the data and Flop meta struct to your
template in the controller.

```elixir
defmodule MyAppWeb.PetController do
  use MyAppWeb, :controller

  alias MyApp.Pets

  action_fallback MyAppWeb.FallbackController

  def index(conn, params) do
    {:ok, {pets, meta}} = Pets.list_pets(params)
    render(conn, :index, meta: meta, pets: pets)
  end
end
```

## HEEx Template

### Sortable table and pagination

To add a sortable table and pagination links, you can add the following to your
template:

```elixir
<h1>Pets</h1>

<Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
  <:col :let={pet} label="Name" field={:name}>{pet.name}</:col>
  <:col :let={pet} label="Age" field={:age}>{pet.age}</:col>
</Flop.Phoenix.table>

<Flop.Phoenix.pagination meta={@meta} path={~p"/pets"} />
```

In this context, `path` points to the current route, and Flop Phoenix appends
pagination, filtering, and sorting parameters to it. You can use verified
routes, route helpers, or custom path builder functions. You can find a
description of the different formats in the documentation for
`Flop.Phoenix.build_path/3`.

Note that the `field` attribute in the `:col` slot is optional. If set and the
corresponding field in the schema is defined as sortable, the table header for
that column will be interactive, allowing users to sort by that column. However,
if the field isn't defined as sortable, or if the field attribute is omitted, or
set to `nil` or `false`, the table header will not be clickable.

By using the `for` option in your Flop query, Flop Phoenix can identify which
table columns are sortable. Additionally, it omits the `order` and `page_size`
parameters if they match the default values defined with `Flop.Schema`.

You also have the option to pass a `Phoenix.LiveView.JS` command instead of or
in addition to a path. For more details, please refer to the component
documentation.

To change the page size, you can either add an HTML `input` control (see below) or
add a LiveView `handle_event/3` function with a corresponding control, such
as a link. For example, you might create a widget with several page-size links.

You could create a `page_size_link` component like this:

```elixir
attr :current_size, :integer, required: true
attr :new_size, :integer, required: true

def page_size_link(assigns) do
  ~H"""
  <.link
    phx-click="page-size"
    phx-value-size={@new_size}
  >
    {@new_size}
  </.link>
  """
end

defp page_size_class(old, old), do: "font-black text-orange-500"
defp page_size_class(_old, _new), do: "font-light"
```

You can then render them like this:

```elixir
<.page_size_link :for={ps <- [10, 20, 40, 60]} new_size={ps} current_size={@meta.page_size} />
```

And add an event handler to the LiveView module:

```elixir
  def handle_event("page-size", %{"size" => ps}, socket) do
    flop = %{socket.assigns.meta.flop | page_size: ps, limit: nil}
    path = Flop.Phoenix.build_path(~p"/pets", flop)

    {:noreply, push_patch(socket, to: path)}
  end
```

This method allows you to update the page size while maintaining browser
history.

### Filter forms

Flop Phoenix implements the `Phoenix.HTML.FormData` for the `Flop.Meta` struct.
As such, you can easily pass the struct to Phoenix form functions. One
straightforward way to render a filter form is through the
`Flop.Phoenix.filter_fields/1` component, as shown below:

```elixir
attr :fields, :list, required: true
attr :meta, Flop.Meta, required: true
attr :id, :string, default: nil
attr :on_change, :string, default: "update-filter"
attr :target, :string, default: nil

def filter_form(%{meta: meta} = assigns) do
  assigns = assign(assigns, form: Phoenix.Component.to_form(meta), meta: nil)

  ~H"""
  <.form
    for={@form}
    id={@id}
    phx-target={@target}
    phx-change={@on_change}
    phx-submit={@on_change}
  >
    <.filter_fields :let={i} form={@form} fields={@fields}>
      <.input
        field={i.field}
        label={i.label}
        type={i.type}
        phx-debounce={120}
        {i.rest}
      />
    </.filter_fields>

    <button class="button" name="reset">reset</button>
  </.form>
  """
end
```

Now you can render a filter form like this:

```elixir
<.filter_form
  fields={[:name, :email]}
  meta={@meta}
  id="user-filter-form"
/>
```

You will need to handle the `update-filter` event with the `handle_event/3`
callback function of your LiveView.

```elixir
@impl true
def handle_event("update-filter", params, socket) do
  params = Map.delete(params, "_target")
  {:noreply, push_patch(socket, to: ~p"/pets?#{params}")}
end
```

Note that while the `filter_fields` component produces all necessary hidden
inputs, it doesn't automatically render inputs for filter values. Instead, it
passes the necessary details to the inner block, allowing you to customize the
filter inputs with your custom input component.

You can pass additional options for each field. Refer to the
`Flop.Phoenix.filter_fields/1` documentation for details.

#### Adding visible inputs for meta parameters

If you want to render visible inputs instead of relying on the hidden input that
are automatically added to the form, you can just add them to the form
component:

```elixir
<.form
  for={@form}
  id={@id}
  phx-target={@target}
  phx-change={@on_change}
  phx-submit={@on_change}
>
  <%!-- ... %>

  <label for="filter-form-page-size">Page size</label>
  <input
    id="filter-form-page-size"
    type="text"
    name="page_size"
    value={@meta.page_size}
  />

  <button class="button" name="reset">reset</button>
</.form>
```

## LiveView streams

To use LiveView streams, you can change your `handle_params/3` function as
follows:

```elixir
def handle_params(params, _, socket) do
  {:ok, {pets, meta}} = Pets.list_pets(params)
  {:noreply, socket |> assign(:meta, meta) |> stream(:pets, pets, reset: true)}
end
```

When using LiveView streams, the data being passed to the table component
differs. Instead of passing `@pets`, you'll need to use `@streams.pets`.

The stream values are tuples, with the DOM ID as the first element and the items
(in this case, Pets) as the second element. You need to match on these tuples
within the `:let` attributes of the table component.

```elixir
<Flop.Phoenix.table items={@streams.pets} meta={@meta} path={~p"/pets"}>
  <:col :let={{_, pet}} label="Name" field={:name}>{pet.name}</:col>
  <:col :let={{_, pet}} label="Age" field={:age}>{pet.age}</:col>
</Flop.Phoenix.table>
```
