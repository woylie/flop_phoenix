# Flop Phoenix

![CI](https://github.com/woylie/flop_phoenix/workflows/CI/badge.svg) [![Hex](https://img.shields.io/hexpm/v/flop_phoenix)](https://hex.pm/packages/flop_phoenix) [![Coverage Status](https://coveralls.io/repos/github/woylie/flop_phoenix/badge.svg)](https://coveralls.io/github/woylie/flop_phoenix)

Flop Phoenix is an Elixir library for filtering, ordering and pagination
with Ecto, Phoenix and [Flop](https://hex.pm/packages/flop).

## Installation

Add `flop_phoenix` to your list of dependencies in the `mix.exs` of your Phoenix
application.

```elixir
def deps do
  [
    {:flop_phoenix, "~> 0.11.1"}
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
    with {:ok, {pets, meta}} <- Pets.list_pets(params) do
      {:noreply, assign(socket, %{pets: pets, meta: meta})}
    end
  end
end
```

## Sortable table and pagination components

In your template, add a sortable table and pagination links.

```elixir
<h1>Pets</h1>

<Flop.Phoenix.table
  items={@pets}
  meta={@meta}
  path_helper={{Routes, :pet_path, [@socket, :index]}}
>
  <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
  <:col let={pet} label="Age" field={:age}><%= pet.age %></:col>
</Flop.Phoenix.table>

<Flop.Phoenix.pagination
  meta={@meta}
  path_helper={{Routes, :pet_path, [@socket, :index]}}
/>
```

`path_helper` should reference the path helper function that builds a path to
the current page. Add any additional path and query parameters to the argument
list.

```elixir
<Flop.Phoenix.pagination
  meta={@meta}
  path_helper={{Routes, :pet_path, [@conn, :index, @owner, [hide_menu: true]]}}
/>
```

If you pass the `for` option when making the query with Flop, Flop Phoenix can
determine which table columns are sortable. It also hides the `order` and
`page_size` parameters if they match the default values defined with
`Flop.Schema`.

## Filter forms

You can render a filter form like this:

```elixir
<.form let={f} for={@meta}>
  <Flop.Phoenix.filter_fields let={elements} form={f} fields={[:name, :email]}>
    <%= elements.label %>
    <%= elements.input %>
  </Flop.Phoenix.filter_fields>
</.form>
```

Refer to the `Flop.Phoenix` module documentation for more examples.
