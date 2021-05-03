defmodule Flop.Phoenix.Pet do
  @moduledoc """
  Defines an Ecto schema for testing.
  """
  use Ecto.Schema

  @derive {
    Flop.Schema,
    filterable: [:name, :age], sortable: [:name, :age]
  }

  schema "pets" do
    field(:name, :string)
    field(:age, :integer)
    field(:species, :string)
  end
end
