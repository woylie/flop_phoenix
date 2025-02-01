defmodule Flop.Phoenix.PaginationTest do
  use ExUnit.Case

  alias Flop.Phoenix.Pagination

  describe "get_page_link_range/3" do
    test "returns nil values for :none option" do
      assert Pagination.get_page_link_range(:none, 1, 10) == {nil, nil}
    end

    test "returns full range for :all option" do
      assert Pagination.get_page_link_range(:all, 4, 10) == {1, 10}
    end

    test "returns page range with odd max pages" do
      assert Pagination.get_page_link_range(3, 1, 10) == {1, 3}
      assert Pagination.get_page_link_range(3, 2, 10) == {1, 3}
      assert Pagination.get_page_link_range(3, 3, 10) == {2, 4}
      assert Pagination.get_page_link_range(3, 4, 10) == {3, 5}
      assert Pagination.get_page_link_range(3, 5, 10) == {4, 6}
      assert Pagination.get_page_link_range(3, 6, 10) == {5, 7}
      assert Pagination.get_page_link_range(3, 7, 10) == {6, 8}
      assert Pagination.get_page_link_range(3, 8, 10) == {7, 9}
      assert Pagination.get_page_link_range(3, 9, 10) == {8, 10}
      assert Pagination.get_page_link_range(3, 10, 10) == {8, 10}
    end

    test "returns page range with even max pages" do
      assert Pagination.get_page_link_range(4, 1, 10) == {1, 4}
      assert Pagination.get_page_link_range(4, 2, 10) == {1, 4}
      assert Pagination.get_page_link_range(4, 3, 10) == {2, 5}
      assert Pagination.get_page_link_range(4, 4, 10) == {3, 6}
      assert Pagination.get_page_link_range(4, 5, 10) == {4, 7}
      assert Pagination.get_page_link_range(4, 6, 10) == {5, 8}
      assert Pagination.get_page_link_range(4, 7, 10) == {6, 9}
      assert Pagination.get_page_link_range(4, 8, 10) == {7, 10}
      assert Pagination.get_page_link_range(4, 9, 10) == {7, 10}
      assert Pagination.get_page_link_range(4, 10, 10) == {7, 10}
    end

    test "does not return range beyond total pages" do
      assert Pagination.get_page_link_range(3, 1, 2) == {1, 2}
    end
  end
end
