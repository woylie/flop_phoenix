defmodule Flop.Phoenix.PaginationTest do
  use ExUnit.Case

  alias Flop.Phoenix.Pagination

  describe "get_page_link_range/3" do
    test "returns page range with odd max pages" do
      assert Pagination.get_page_link_range(1, 3, 10) == 1..3
      assert Pagination.get_page_link_range(2, 3, 10) == 1..3
      assert Pagination.get_page_link_range(3, 3, 10) == 2..4
      assert Pagination.get_page_link_range(4, 3, 10) == 3..5
      assert Pagination.get_page_link_range(5, 3, 10) == 4..6
      assert Pagination.get_page_link_range(6, 3, 10) == 5..7
      assert Pagination.get_page_link_range(7, 3, 10) == 6..8
      assert Pagination.get_page_link_range(8, 3, 10) == 7..9
      assert Pagination.get_page_link_range(9, 3, 10) == 8..10
      assert Pagination.get_page_link_range(10, 3, 10) == 8..10
    end

    test "returns page range with even max pages" do
      assert Pagination.get_page_link_range(1, 4, 10) == 1..4
      assert Pagination.get_page_link_range(2, 4, 10) == 1..4
      assert Pagination.get_page_link_range(3, 4, 10) == 2..5
      assert Pagination.get_page_link_range(4, 4, 10) == 3..6
      assert Pagination.get_page_link_range(5, 4, 10) == 4..7
      assert Pagination.get_page_link_range(6, 4, 10) == 5..8
      assert Pagination.get_page_link_range(7, 4, 10) == 6..9
      assert Pagination.get_page_link_range(8, 4, 10) == 7..10
      assert Pagination.get_page_link_range(9, 4, 10) == 7..10
      assert Pagination.get_page_link_range(10, 4, 10) == 7..10
    end

    test "does not return range beyond total pages" do
      assert Pagination.get_page_link_range(1, 3, 2) == 1..2
    end
  end
end
