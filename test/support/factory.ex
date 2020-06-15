defmodule FlopPhoenix.Factory do
  @moduledoc false
  use ExMachina

  alias Flop.Meta

  def meta_factory do
    %Meta{
      current_offset: 0,
      current_page: 1,
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

  def meta_one_page_factory do
    %Meta{
      current_offset: 0,
      current_page: 1,
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
end
