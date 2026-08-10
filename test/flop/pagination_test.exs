defmodule Flop.Phoenix.PaginationTest do
  use ExUnit.Case, async: true

  alias Flop.Meta
  alias Flop.Phoenix.Pagination

  describe "new/2" do
    test "sets both ellipsis flags to false without page links" do
      meta = %Meta{
        flop: %Flop{page: 2, page_size: 10},
        has_next_page?: true,
        has_previous_page?: true,
        current_page: 2,
        total_pages: 20
      }

      assert %Pagination{
               ellipsis_start?: false,
               ellipsis_end?: false,
               page_range_start: nil,
               page_range_end: nil
             } = Pagination.new(meta, page_links: :none)
    end

    test "raises error for a Flop without pagination parameters" do
      meta = %Meta{flop: %Flop{}, errors: []}

      assert_raise ArgumentError, ~r/No pagination parameters/, fn ->
        Pagination.new(meta)
      end
    end
  end
end
