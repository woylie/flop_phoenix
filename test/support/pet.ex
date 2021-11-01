defmodule Flop.Phoenix.Pet do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ecto.Schema

  @derive {
    Flop.Schema,
    filterable: [:name, :age],
    sortable: [:name, :age],
    default_limit: 20,
    max_limit: 200,
    default_order_by: [:name],
    default_order_directions: [:asc]
  }

  schema "pets" do
    field(:name, :string)
    field(:age, :integer)
    field(:species, :string)
  end
end
