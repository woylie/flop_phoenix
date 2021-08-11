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
    {:flop_phoenix, "~> 0.7.0"}
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

## HEEx templates

In your template, add a sortable table and pagination links.

```elixir
<h1>Pets</h1>

<Flop.Phoenix.table
  items={@pets}
  meta={@meta}
  path_helper={&Routes.pet_path/3}
  path_helper_args={[@socket, :index]}
  headers={[{"Name", :name}, {"Age", :age}]}
  row_func={fn pet, _opts -> [pet.name, pet.age] end},
  opts={[for: MyApp.Pet]}
/>

<Flop.Phoenix.pagination
  meta={@meta},
  path_helper={&Routes.pet_path/3},
  path_helper_args{[@socket, :index]},
  opts={[for: MyApp.Pet]}
/>
```

`path_helper` should reference the path helper function that builds a path to
the current page. `path_helper_args` is the argument list that will be passed to
the function. If you want to add a path parameter, you can do it like this.

```elixir
<Flop.Phoenix.pagination
  meta={@meta},
  path_helper={&Routes.pet_path/4},
  path_helper_args{[@conn, :index, @owner]},
  opts={[for: MyApp.Pet]}
/>
```

If the last argument is a keyword list of query parameters, the query parameters
for pagination and sorting will be merged into that list.

The `for` option allows Flop Phoenix to determine which table columns are
sortable. It also allows it to hide the `order` and `page_size`
parameters if they match the default values defined with `Flop.Schema`.

## EEx templates

In EEX templates, you will need to call the functions directly and pass a map
with the assigns. You need to include `__changed__: nil` in the map. Do not call
the functions like this within a LiveView, since it will prevent the components
from being updated.

```elixir
<h1>Pets</h1>

<%= table(%{
      __changed__: nil,
      items: @pets,
      meta: @meta,
      path_helper: &Routes.pet_path/3,
      path_helper_args: [@conn, :index],
      headers: [{"Name", :name}, {"Age", :age}],
      row_func: fn pet, _opts -> [pet.name, pet.age] end,
      opts: [for: MyApp.Pet]
    })
%>

<%= pagination(%{
      __changed__: nil,
      meta: @meta,
      path_helper: &Routes.pet_path/3,
      path_helper_args: [@conn, :index],
      opts: [for: MyApp.Pet]
    })
%>
```

## Clean up the template

To keep your templates clean, it is recommended to define a `table_headers/1`
and `table_row/2` function in your `View`, `LiveView` or `LiveComponent` module.
The `opts` are passed as a second argument to the `row_func`, so you can add any
additional parameters you need.

The LiveView module:

```elixir
defmodule MyAppWeb.PetLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Pet
  alias MyApp.Pets

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    with {:ok, {pets, meta}} <- Pets.list_pets(params) do
      {:noreply, assign(socket, %{pets: pets, meta: meta})}
    end
  end

  def table_headers do
    [
      # {display value, schema field}
      {"Name", :name},
      {"Age", :age},
      ""
    ]
  end

  def table_row(%Pet{} = pet, opts) do
    socket = Keyword.fetch!(opts, :socket)

    [
      pet.name,
      pet.age,
      link "show", to: Routes.pet_path(socket, :show, pet)
    ]
  end
end
```

The template:

```elixir
<Flop.Phoenix.table
  items={@pets}
  meta={@meta}
  path_helper={&Routes.pet_path/3}
  path_helper_args={[@socket, :index]}
  headers={table_headers()}
  row_func={&table_row/2},
  opts={[for: MyApp.Pet, socket: @socket]}
/>
```

## Customization

If you want to customize the pagination or table markup, you would probably want
to do that once for all templates.

To do that, create a new file `live/flop_components.ex` (or
`views/flop_helpers.ex`, or `views/component_helpers.ex`).

```elixir
defmodule MyAppWeb.FlopComponents do
  use Phoenix.Component

  def pagination(assigns) do
    ~H"""
    <Flop.Phoenix.pagination
      meta={@meta},
      path_helper={@path_helper},
      path_helper_args{@path_helper_args},
      opts={pagination_opts(@opts)}
    />
    """
  end

  defp pagination_opts(opts) do
    default_opts = [
      next_link_content: next_icon(),
      previous_link_content: previous_icon(),
      wrapper_attrs: [class: "paginator"]
    ]

    Keyword.merge(default_opts, opts)
  end

  defp next_icon do
    tag :i, class: "fas fa-chevron-right"
  end

  defp previous_icon do
    tag :i, class: "fas fa-chevron-left"
  end
end
```

To make the functions available in all templates, import the module in
`my_app_web.ex`.

```diff
defp view_helpers do
  quote do
    # ...

+   import MyAppWeb.FlopComponents

    # ...
  end
end
```

You can do so similarly for `Flop.Phoenix.table/1`

Refer to the `Flop.Phoenix` module documentation for more examples.
