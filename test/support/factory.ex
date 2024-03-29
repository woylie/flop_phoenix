defmodule Flop.Phoenix.Factory do
  @moduledoc false
  use ExMachina

  alias Flop.Meta

  def meta_on_first_page_factory do
    %Meta{
      current_offset: 0,
      current_page: 1,
      flop: %Flop{page: 1, page_size: 10},
      has_next_page?: true,
      has_previous_page?: false,
      next_offset: 10,
      next_page: 2,
      page_size: 10,
      previous_offset: nil,
      previous_page: nil,
      total_count: 42,
      total_pages: 5
    }
  end

  def meta_on_second_page_factory do
    %Meta{
      current_offset: 10,
      current_page: 2,
      flop: %Flop{page: 2, page_size: 10},
      has_next_page?: true,
      has_previous_page?: true,
      next_offset: 10,
      next_page: 3,
      page_size: 10,
      previous_offset: 0,
      previous_page: 1,
      total_count: 42,
      total_pages: 5
    }
  end

  def meta_on_last_page_factory do
    %Meta{
      current_offset: 40,
      current_page: 5,
      flop: %Flop{page: 5, page_size: 10},
      has_next_page?: false,
      has_previous_page?: true,
      next_offset: 10,
      next_page: nil,
      page_size: 10,
      previous_offset: 30,
      previous_page: 4,
      total_count: 42,
      total_pages: 5
    }
  end

  def meta_one_page_factory do
    %Meta{
      current_offset: 0,
      current_page: 1,
      flop: %Flop{page: 1, page_size: 10},
      has_next_page?: false,
      has_previous_page?: false,
      next_offset: nil,
      next_page: nil,
      page_size: 10,
      previous_offset: nil,
      previous_page: nil,
      total_count: 6,
      total_pages: 1
    }
  end

  def meta_no_results_factory do
    %Meta{
      current_offset: 0,
      current_page: 1,
      flop: %Flop{page: 1, page_size: 10},
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
  end

  def meta_with_cursors_factory do
    %Meta{
      flop: %Flop{first: 10, after: "A", page_size: 10},
      has_next_page?: true,
      has_previous_page?: true,
      start_cursor: "B",
      end_cursor: "C"
    }
  end
end
