defmodule Flop.Phoenix.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Flop.Phoenix

  alias Flop.Filter
  alias Plug.Conn.Query

  @path "/pets"

  property "build_path/3 encodes exactly the parameters of to_query/2" do
    check all flop <- flop() do
      assert decoded_query(build_path(@path, flop)) ==
               flop |> to_query() |> Query.encode() |> Query.decode()
    end
  end

  property "build_path/3 is idempotent" do
    check all flop <- flop() do
      path = build_path(@path, flop)

      assert decoded_query(build_path(path, flop)) == decoded_query(path)
    end
  end

  property "build_path/3 replaces the parameters of an earlier Flop struct" do
    check all flop <- flop(),
              stale <- flop() do
      stale_path = build_path(@path, stale)

      assert decoded_query(build_path(stale_path, flop)) ==
               decoded_query(build_path(@path, flop))
    end
  end

  defp decoded_query(path) do
    %URI{query: query} = URI.parse(path)
    Query.decode(query || "")
  end

  defp flop do
    gen all pagination <- pagination(),
            order <- order(),
            filters <- list_of(filter(), max_length: 3) do
      struct(Flop, Map.put(Map.merge(pagination, order), :filters, filters))
    end
  end

  defp pagination do
    one_of([
      constant(%{}),
      fixed_map(%{page: positive_integer(), page_size: positive_integer()}),
      fixed_map(%{
        limit: positive_integer(),
        offset: map(positive_integer(), &(&1 - 1))
      }),
      fixed_map(%{first: positive_integer(), after: cursor()}),
      fixed_map(%{last: positive_integer(), before: cursor()})
    ])
  end

  defp cursor, do: string(:printable, max_length: 20)

  defp order do
    gen all fields <- map(list_of(field(), max_length: 3), &Enum.uniq/1),
            directions <- list_of(direction(), length: length(fields)) do
      %{order_by: fields, order_directions: directions}
    end
  end

  defp filter do
    gen all field <- field(),
            op <- op(),
            value <- filter_value() do
      %Filter{field: field, op: op, value: value}
    end
  end

  defp field, do: member_of([:name, :age, :species])

  defp op, do: member_of([:==, :!=, :ilike, :>=, :<=, :in, :empty])

  defp filter_value do
    one_of([
      string(:printable, max_length: 20),
      integer(),
      boolean(),
      list_of(string(:alphanumeric, max_length: 5), max_length: 3)
    ])
  end

  defp direction do
    member_of([
      :asc,
      :asc_nulls_first,
      :asc_nulls_last,
      :desc,
      :desc_nulls_first,
      :desc_nulls_last
    ])
  end
end
