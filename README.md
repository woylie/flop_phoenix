# Flop Phoenix

![CI](https://github.com/woylie/flop_phoenix/workflows/CI/badge.svg) [![Hex](https://img.shields.io/hexpm/v/flop_phoenix)](https://hex.pm/packages/flop_phoenix) [![Coverage Status](https://coveralls.io/repos/github/woylie/flop_phoenix/badge.svg)](https://coveralls.io/github/woylie/flop_phoenix)

Phoenix components for pagination, sortable tables and filter forms with
[Flop](https://hex.pm/packages/flop) and [Ecto](https://hex.pm/packages/ecto).

## Installation

Add `flop_phoenix` to your list of dependencies in the `mix.exs` of your Phoenix
application.

```elixir
def deps do
  [
    {:flop_phoenix, "~> 0.17.0"}
  ]
end
```

Follow the instructions in the
[Flop documentation](https://hex.pm/packages/flop) to set up your business
logic.

## Fetch the data

Define a function that calls `Flop.validate_and_run/3` to query the list of
pets.

```elixir
defmodule MyApp.Pets do
  alias MyApp.Pet

  def list_pets(params) do
    Flop.validate_and_run(Pet, params, for: Pet)
  end
end
```

In your controller, pass the data and the Flop meta struct to your template.

```elixir
defmodule MyAppWeb.PetController do
  use MyAppWeb, :controller

  alias MyApp.Pets

  action_fallback MyAppWeb.FallbackController

  def index(conn, params) do
    with {:ok, {pets, meta}} <- Pets.list_pets(params) do
      render(conn, "index.html", meta: meta, pets: pets)
    end
  end
end
```

You can fetch the data similarly in the `handle_params/3` function of a
`LiveView` or the `update/2` function of a `LiveComponent`.

```elixir
defmodule MyAppWeb.PetLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Pets

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    case Pets.list_pets(params) do
      {:ok, {pets, meta}} ->
        {:noreply, assign(socket, %{pets: pets, meta: meta})}

      _ ->
        {:noreply, push_navigate(socket, to: Routes.pet_index_path(socket, :index))}
    end
  end
end
```

## Sortable tables and pagination

In your template, add a sortable table and pagination links.

```elixir
<h1>Pets</h1>

<Flop.Phoenix.table
  items={@pets}
  meta={@meta}
  path={{Routes, :pet_path, [@socket, :index]}}
>
  <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
  <:col :let={pet} label="Age" field={:age}><%= pet.age %></:col>
</Flop.Phoenix.table>

<Flop.Phoenix.pagination
  meta={@meta}
  path={{Routes, :pet_path, [@socket, :index]}}
/>
```

`path` should reference the path helper function that builds a path to
the current page. Add any additional path and query parameters to the argument
list.

```elixir
<Flop.Phoenix.pagination
  meta={@meta}
  path={{Routes, :pet_path, [@conn, :index, @owner, [hide_menu: true]]}}
/>
```

Alternatively, you can pass a URI string, which allows you to use the
verified routes introduced in Phoenix 1.7.

```elixir
<Flop.Phoenix.pagination
  meta={@meta}
  path={~p"/pets"}
/>
```

You can also use a custom path builder function, in case you need to set some
parameters in the path instead of the query. For more examples, have a look at
the documentation of `Flop.Phoenix.build_path/3`. The `path` assign can use any
format that is accepted by `Flop.Phoenix.build_path/3`.

If you pass the `for` option when making the query with Flop, Flop Phoenix can
determine which table columns are sortable. It also hides the `order` and
`page_size` parameters if they match the default values defined with
`Flop.Schema`.

See `Flop.Phoenix.cursor_pagination/1` for instructions to set up cursor-based
pagination.

## Filter forms

This library implements `Phoenix.HTML.FormData` for the `Flop.Meta` struct,
which means you can pass the struct to the Phoenix form functions. The
easiest way to render a filter form is to use the `Flop.Phoenix.filter_fields/1`
component:

```elixir
<.form :let={f} for={@meta}>
  <.filter_fields :let={i} form={f} fields={[:email, :name]}>
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
```

The `filter_fields` component renders all necessary hidden inputs, but it does
not render the inputs for the filter values on its own. Instead, it passes all
necessary details to the inner block. This allows you to render the filter
inputs with your custom input component.

You can pass additional options for each field. Refer to the
`Flop.Phoenix.filter_fields/1` documentation for details.

### Custom filter form component

It is recommended to define a custom `filter_form` component that wraps
`Flop.Phoenix.filter_fields/1`, so that you can apply the same markup
throughout your live views.

```elixir
attr :meta, Flop.Meta, required: true
attr :fields, :list, required: true
attr :id, :string, default: nil
attr :change_event, :string, default: "update-filter"
attr :reset_event, :string, default: "reset-filter"
attr :target, :string, default: nil
attr :debounce, :integer, default: 100

def filter_form(assigns) do
  ~H"""
  <div class="filter-form">
    <.form
      :let={f}
      for={@meta}
      as={:filter}
      id={@id}
      phx-target={@target}
      phx-change={@change_event}
    >
      <div class="filter-form-inputs">
        <Flop.Phoenix.filter_fields :let={i} form={f} fields={@fields}>
          <.input
            id={i.id}
            name={i.name}
            label={i.label}
            type={i.type}
            value={i.value}
            field={{i.form, i.field}}
            hide_labels={true}
            phx-debounce={@debounce}
            {i.rest}
          />
        </Flop.Phoenix.filter_fields>
      </div>

      <div class="filter-form-reset">
        <a href="#" class="button" phx_target={@target} phx_click={@reset_event}>
          reset
        </a>
      </div>
    </.form>
  </div>
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

You will need to handle the `update-filter` and `reset-filter` events with the
`handle_event/3` callback function of your LiveView.

```elixir
@impl true
def handle_event("update-filter", %{"filter" => params}, socket) do
  {:noreply,
   push_patch(socket, to: Routes.pet_index_path(socket, :index, params))}
end

@impl true
def handle_event("reset-filter", _, %{assigns: assigns} = socket) do
  flop = assigns.meta.flop |> Flop.set_page(1) |> Flop.reset_filters()

  path =
    Flop.Phoenix.build_path(
      {Routes, :pet_index_path, [socket, :index]},
      flop,
      backend: assigns.meta.backend
    )

  {:noreply, push_patch(socket, to: path)}
end
```
