defmodule FlopPhoenixTest do
  use ExUnit.Case

  import FlopPhoenix
  import Phoenix.HTML

  alias Flop.Meta

  doctest FlopPhoenix

  @meta %Meta{
    current_offset: 0,
    current_page: 1,
    has_next_page?: false,
    has_previous_page?: false,
    next_offset: nil,
    next_page: nil,
    page_size: 10,
    previous_offset: nil,
    previous_page: nil,
    total_count: 0,
    total_pages: 0
  }

  @route_helper_opts [%{}, :dance]

  defp route_helper(%{}, action, query) do
    URI.to_string(%URI{path: "/#{action}", query: URI.encode_query(query)})
  end

  describe "pagination/4" do
    test "renders pagination wrapper" do
      result =
        @meta
        |> pagination(&route_helper/3, @route_helper_opts)
        |> safe_to_string()

      assert result ==
               "<nav aria-label=\"pagination\" class=\"pagination\" role=\"navigation\"></nav>"
    end

    test "allows to overwrite wrapper class" do
      result =
        @meta
        |> pagination(&route_helper/3, @route_helper_opts, wrapper_class: "boo")
        |> safe_to_string()

      assert result ==
               "<nav aria-label=\"pagination\" class=\"boo\" role=\"navigation\"></nav>"
    end
  end
end
