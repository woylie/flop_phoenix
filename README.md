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
    {:flop_phoenix, "~> 0.17.2"}
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

### LiveView

Fetch the data and assign it along with the meta data to the socket.

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
        {:noreply, push_navigate(socket, to: ~p"/pets")}
    end
  end
end
```

If you don't want the `Flop.Phoenix` components to reflect the pagination,
sorting and filtering parameters in the URL, you can fetch and assign the data
in the `c:Phoenix.LiveView.handle_event/3` callback instead. In that case, you
need to pass the event name as an attribute to the components.

### Controller

For dead views, pass the data and the Flop meta struct to your template in your controller.

```elixir
defmodule MyAppWeb.PetController do
  use MyAppWeb, :controller

  alias MyApp.Pets

  action_fallback MyAppWeb.FallbackController

  def index(conn, params) do
    with {:ok, {pets, meta}} <- Pets.list_pets(params) do
      render(conn, :index, meta: meta, pets: pets)
    end
  end
end
```

## Sortable tables and pagination

In your template, add a sortable table and pagination links.

```elixir
<h1>Pets</h1>

<Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
  <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
  <:col :let={pet} label="Age" field={:age}><%= pet.age %></:col>
</Flop.Phoenix.table>

<Flop.Phoenix.pagination meta={@meta} path={~p"/pets"} />
```

The `path` attribute points to the current path. `Flop.Phoenix` will add the pagination, filtering and sorting parameters to that path. You can use verified
routes, route helpers, or custom path builder functions. The different formats
are explained in the documentation of `Flop.Phoenix.build_path/3`.

If you pass the `for` option when making the query with Flop, Flop Phoenix can
determine which table columns are sortable. It also hides the `order` and
`page_size` parameters if they match the default values defined with
`Flop.Schema`.

Alternatively, you can pass an event name instead of a path. Refer to the
component documentation for details.

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
        <a href="#" class="button" phx-target={@target} phx-click={@reset_event}>
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
  {:noreply, push_patch(socket, to: ~p"/pets?#{params}")}
end

@impl true
def handle_event("reset-filter", _, %{assigns: assigns} = socket) do
  flop = assigns.meta.flop |> Flop.set_page(1) |> Flop.reset_filters()
  path = Flop.Phoenix.build_path(~p"/pets", flop, backend: assigns.meta.backend)
  {:noreply, push_patch(socket, to: path)}
end
```
