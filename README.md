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
    {:flop_phoenix, "~> 0.1.0"}
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

In `my_app_web.ex`, find the `view_helpers/0` macro and import `FlopPhoenix`:

```diff
defp view_helpers do
  quote do
    # Use all HTML functionality (forms, tags, etc)
    use Phoenix.HTML

    # Import basic rendering functionality (render, render_layout, etc)
    import Phoenix.View

+   import FlopPhoenix

    import MyAppWeb.ErrorHelpers
    import MyAppWeb.Gettext
    alias MyAppWeb.Router.Helpers, as: Routes
  end
end
```

In your index template, you can now add pagination links:

```elixir
<h1>Listing Pets</h1>

<table>
# ...
</table>

<%= pagination(@meta, &Routes.pet_path/3, [@conn, :index]) %>

<span><%= link "New Pet", to: Routes.pet_path(@conn, :new) %></span>
```

The second argument of `FlopPhoenix.pagination/4` is the route helper function,
and the third argument is a list of arguments for that route helper. If you
want to add path parameters, you can do that like this:

```elixir
<%= pagination(@meta, &Routes.owner_pet_path/4, [@conn, :index, @owner]) %>
```

## Customization

If you want to customize the pagination markup, you would probably want to do
that once for all templates. To do that, create a new file
`views/flop_helpers.ex`.

```elixir
defmodule MyAppWeb.FlopHelpers do
  def pagination(meta, route_helper, route_helper_args) do
    opts = [
      next_link_content:
        content_tag :i, class: "fas fa-chevron-next" do
        end,
      previous_link_content:
        content_tag :i, class: "fas fa-chevron-left" do
        end,
      wrapper_attrs: [class: "paginator"]
    ]

    FlopPhoenix.pagination(meta, route_helper, route_helper_args, opts)
  end
end
```

Refer to the `FlopPhoenix` docs for more information on the available options.
