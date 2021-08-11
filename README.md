# Flop Phoenix

![CI](https://github.com/woylie/flop_phoenix/workflows/CI/badge.svg) [![Hex](https://img.shields.io/hexpm/v/flop_phoenix)](https://hex.pm/packages/flop_phoenix) [![Coverage Status](https://coveralls.io/repos/github/woylie/flop_phoenix/badge.svg)](https://coveralls.io/github/woylie/flop_phoenix)

Flop Phoenix is an Elixir library for filtering, ordering and pagination
with Ecto, Phoenix and [Flop](https://hex.pm/packages/flop).

## Installation

Add `flop_phoenix` to your list of dependencies in the `mix.exs` of your Phoenix
application:

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

## Usage

In your controller, pass the data and the Flop meta struct to your template:

```elixir
defmodule MyAppWeb.PetController do
  use MyAppWeb, :controller

  alias Flop
  alias MyApp.Pets
  alias MyApp.Pets.Pet

  action_fallback MyAppWeb.FallbackController

  def index(conn, params) do
    with {:ok, {pets, meta}} <- Pets.list_pets(params) do
      render(conn, "index.html", meta: meta, pets: pets)
    end
  end
end
```

In `my_app_web.ex`, find the `view_helpers/0` macro and import `Flop.Phoenix`:

```diff
defp view_helpers do
  quote do
    # Use all HTML functionality (forms, tags, etc)
    use Phoenix.HTML

    # Import basic rendering functionality (render, render_layout, etc)
    import Phoenix.View

+   import Flop.Phoenix

    import MyAppWeb.ErrorHelpers
    import MyAppWeb.Gettext
    alias MyAppWeb.Router.Helpers, as: Routes
  end
end
```

In your index template, you can now add a sortable table and pagination links:

```elixir
<h1>Pets</h1>

<%= table(%{
      items: @pets,
      meta: @meta,
      path_helper: &Routes.pet_path/3,
      path_helper_args: [@conn, :index],
      headers: [{"Name", :name}, {"Age", :age}],
      row_func: fn pet, _opts -> [pet.name, pet.age] end,
      opts: [for: MyApp.Pet]
  })
%>

<%= pagination(@meta, &Routes.pet_path/3, [@conn, :index], for: MyApp.Pet) %>
```

The second argument of `Flop.Phoenix.pagination/1` is the path helper function,
and the third argument is a list of arguments for that path helper. If you
want to add path parameters, you can do it like this:

```elixir
<%= pagination(@meta, &Routes.owner_pet_path/4, [@conn, :index, @owner]) %>
```

This works the same as the `path_helper` and `path_helper_args` values of
`Flop.Phoenix.table/1`.

The `for` option allows Flop Phoenix to hide the `order` and `page_size`
parameters if they match the default values defines with `Flop.Schema`.

To keep your template clean, it is recommended to define a `table_headers/1`
and `table_row/2` function in your view. The `opts` are passed as a second
argument to the `row_func`, so you can add any additional parameters you need.

The view module:

```elixir
defmodule MyApp.PetView do
  def table_headers do
    [
      # {display value, schema field}
      {"Name", :name},
      {"Age", :age},
      ""
    ]
  end

  def table_row(%Pet{} = pet, opts) do
    conn = Keyword.fetch!(opts, :conn)

    [
      pet.name,
      pet.age,
      link "show", to: Routes.pet_path(conn, :show, pet)
    ]
  end
end
```

The template:

```elixir
<%= table(%{
      items: @pets,
      meta: @meta,
      path_helper: &Routes.pet_path/3,
      path_helper_args: [@conn, :index],
      headers: table_headers(),
      row_func: &table_row/2,
      opts: [conn: @conn, for: Pet]
  })
%>
```

## Customization

If you want to customize the pagination or table markup, you would probably want
to do that once for all templates. To do that, create a new file
`views/flop_helpers.ex` (or maybe `views/component_helpers.ex`).

```elixir
defmodule MyAppWeb.FlopHelpers do
  use Phoenix.HTML

  def pagination(meta, route_helper, route_helper_args) do
    opts = [
      next_link_content: next_icon(),
      previous_link_content: previous_icon(),
      wrapper_attrs: [class: "paginator"]
    ]

    Flop.Phoenix.pagination(meta, route_helper, route_helper_args, opts)
  end

  defp next_icon do
    tag :i, class: "fas fa-chevron-right"
  end

  defp previous_icon do
    tag :i, class: "fas fa-chevron-left"
  end
end
```

Change the import in `my_app_web.ex`:

```diff
defp view_helpers do
  quote do
    # ...

-   import Flop.Phoenix
+   import MyAppWeb.FlopHelpers

    # ...
  end
end
```

You can do it similarly for `Flop.Phoenix.table/1`

Refer to the `Flop.Phoenix` module documentation for more examples.
