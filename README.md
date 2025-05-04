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
    {:flop_phoenix, "~> 0.24.0"}
  ]
end
```

Next, set up your business logic following the
[Flop documentation](https://hex.pm/packages/flop).

## Usage

### Context

Define a context function that performs a list query using Flop.

```elixir
defmodule MyApp.Pets do
  alias MyApp.Pet

  def list_pets(params) do
    Flop.validate_and_run!(Pet, params, for: Pet, replace_invalid_params: true)
  end
end
```

Note the usage of the `replace_invalid_params` option, which lets Flop ignore
invalid parameters instead of producing an error.

### LiveView

In the `handle_params` function of your LiveView module, pass the parameters
to the list function to fetch the data and assign both the data and the meta
struct to the socket.

```elixir
defmodule MyAppWeb.PetLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Pets

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {pets, meta} = Pets.list_pets(params)
    {:noreply, assign(socket, pets: pets, meta: meta)}
  end
end
```

### Sortable table and pagination

Add a sortable table and pagination to your HEEx template:

```heex
<Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
  <:col :let={pet} label="Name" field={:name}>{pet.name}</:col>
  <:col :let={pet} label="Age" field={:age}>{pet.age}</:col>
</Flop.Phoenix.table>

<Flop.Phoenix.pagination meta={@meta} path={~p"/pets"} />
```

The `path` attribute points to the current route, and Flop Phoenix appends
pagination, filtering, and sorting parameters to it. You can use verified
routes, route helpers, or custom path builder functions. For a
description of the different formats, refer to the documentation of
`Flop.Phoenix.build_path/3`.

The `field` attribute in the `:col` slot is optional. If set and the field
is defined as sortable in the Ecto schema, the table header for
that column will be interactive, allowing users to sort by that column. However,
if the field isn't defined as sortable, or if the field attribute is omitted, or
set to `nil` or `false`, the table header will not be clickable.

By using the `for` option in your Flop query, Flop Phoenix can identify which
table columns are sortable. Additionally, it omits the `order` and `page_size`
parameters if they match the default values defined with `Flop.Schema`.

You also have the option to pass a `Phoenix.LiveView.JS` command instead of or
in addition to a path. For more details, please refer to the component
documentation.

The pagination component can be used for both page-based pagination and
cursor-based pagination. It chooses the pagination type based on the information
from the `Flop.Meta` struct.

### Event-based pagination and sorting

In the example above, the pagination, sorting, and filtering parameters are
appended to the URL as query parameters. Most of the time, this provides a
better user experience, since users are able to bookmark or share a URL that
leads to the exact view.

In some cases, though, you may prefer not to handle the parameters via the URL.
For example, you may have multiple pageable areas in a single view, or a
pageable widget that is not part of the main content.

In that case, you can set the `on_paginate` and `on_sort` attributes instead of
the `path` attribute and handle these events with the `handle_event` callback.

Refer to the "Using JS commands" section in the `Flop.Phoenix` module
documentation for an example.

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

    <button name="reset">reset</button>
  </.form>
  """
end
```

Now you can render a filter form like this:

```heex
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
filter inputs with your own input component.

You can pass additional options for each field. Refer to the
`Flop.Phoenix.filter_fields/1` documentation for details.

#### Adding visible inputs for meta parameters

If you want to render visible inputs instead of relying on the hidden inputs
that are automatically added to the form, you can just add them to the form
component:

```heex
<.form
  for={@form}
  id={@id}
  phx-target={@target}
  phx-change={@on_change}
  phx-submit={@on_change}
>
  <%!-- ... --%>

  <label for="filter-form-page-size">Page size</label>
  <input
    id="filter-form-page-size"
    type="text"
    name="page_size"
    value={@meta.page_size}
  />

  <button name="reset">reset</button>
</.form>
```

`Phoenix.LiveView.JS` command as an attribute to the components in that case.

## Customization

For customizing the components, it is recommend to define wrapper components
that set the necessary attributes. Refer to the
[module documentation](https://hexdocs.pm/flop_phoenix/Flop.Phoenix.html#module-customization) for examples.

## LiveView streams

To use LiveView streams, you can change your `handle_params/3` function as
follows:

```elixir
def handle_params(params, _, socket) do
  {:ok, {pets, meta}} = Pets.list_pets(params)
  {:noreply, socket |> assign(:meta, meta) |> stream(:pets, pets, reset: true)}
end
```

When using LiveView streams, you need to pass `@streams.pets` instead of `@pets`
to the table component.

The stream values are tuples, with the DOM ID as the first element and the items
(in this case, Pets) as the second element. You need to match on these tuples
within the `:let` attributes of the table component.

```heex
<Flop.Phoenix.table items={@streams.pets} meta={@meta} path={~p"/pets"}>
  <:col :let={{_, pet}} label="Name" field={:name}>{pet.name}</:col>
  <:col :let={{_, pet}} label="Age" field={:age}>{pet.age}</:col>
</Flop.Phoenix.table>
```
