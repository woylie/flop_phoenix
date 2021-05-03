defmodule Flop.PhoenixTest do
  use ExUnit.Case
  use Phoenix.HTML

  import Flop.Phoenix
  import Flop.Phoenix.Factory

  alias Flop.Meta
  alias Plug.Conn.Query

  doctest Flop.Phoenix, import: true

  @route_helper_opts [%{}, :pets]

  defp count_substrings(str, regex) do
    regex
    |> Regex.scan(str)
    |> length()
  end

  defp render_pagination(%Meta{} = meta, opts \\ []) do
    meta
    |> pagination(&route_helper/3, @route_helper_opts, opts)
    |> safe_to_string()
  end

  defp route_helper(%{}, path, query) do
    URI.to_string(%URI{path: "/#{path}", query: Query.encode(query)})
  end

  describe "pagination/4" do
    test "renders pagination wrapper" do
      result = render_pagination(build(:meta_on_first_page))

      assert String.starts_with?(
               result,
               ~s(<nav aria-label="pagination" class="pagination" ) <>
                 ~s(role="navigation">)
             )

      assert String.ends_with?(result, "</nav>")
    end

    test "does not render anything if there is only one page" do
      assert render_pagination(build(:meta_one_page)) == ""
    end

    test "does not render anything if there are no results" do
      assert render_pagination(build(:meta_no_results)) == ""
    end

    test "allows to overwrite wrapper class" do
      result =
        render_pagination(build(:meta_on_first_page),
          wrapper_attrs: [class: "boo"]
        )

      assert result =~
               ~s(<nav aria-label="pagination" class="boo" ) <>
                 ~s(role="navigation">)
    end

    test "allows to add attributes to wrapper" do
      result =
        render_pagination(build(:meta_on_first_page),
          wrapper_attrs: [title: "paginate"]
        )

      assert result =~
               ~s(<nav aria-label="pagination" class="pagination" ) <>
                 ~s(role="navigation" title="paginate">)
    end

    test "renders previous link" do
      result = render_pagination(build(:meta_on_second_page))

      assert result =~
               ~s(<a class="pagination-previous" ) <>
                 ~s(href="/pets?page=1&amp;page_size=10">Previous</a>)
    end

    test "merges query parameters into existing parameters" do
      result =
        :meta_on_second_page
        |> build()
        |> pagination(
          &route_helper/3,
          @route_helper_opts ++ [[category: "dinosaurs"]]
        )
        |> safe_to_string()

      assert result =~
               ~s(<a class="pagination-previous" ) <>
                 ~s(href="/pets?page=1&amp;category=dinosaurs&amp;page_size=10">Previous</a>)
    end

    test "allows to overwrite previous link attributes and content" do
      result =
        render_pagination(
          build(:meta_on_second_page),
          previous_link_attrs: [class: "prev", title: "p-p-previous"],
          previous_link_content:
            content_tag :i, class: "fas fa-chevron-left" do
            end
        )

      assert result =~
               ~s(<a class="prev" href="/pets?page=1&amp;page_size=10" ) <>
                 ~s(title="p-p-previous">) <>
                 ~s(<i class="fas fa-chevron-left"></i></a>)
    end

    test "disables previous link if on first page" do
      result = render_pagination(build(:meta_on_first_page))

      assert result =~
               ~s(<span class="pagination-previous" disabled="disabled">) <>
                 ~s(Previous</span>)
    end

    test "allows to overwrite previous link class and content if disabled" do
      result =
        render_pagination(
          build(:meta_on_first_page),
          previous_link_attrs: [class: "prev", title: "no"],
          previous_link_content: "Prev"
        )

      assert result =~
               ~s(<span class="prev" disabled="disabled" title="no">) <>
                 ~s(Prev</span>)
    end

    test "renders next link" do
      result = render_pagination(build(:meta_on_second_page))

      assert result =~
               ~s(<a class="pagination-next" ) <>
                 ~s(href="/pets?page=3&amp;page_size=10">Next</a>)
    end

    test "allows to overwrite next link attributes and content" do
      result =
        render_pagination(
          build(:meta_on_second_page),
          next_link_attrs: [class: "next", title: "back"],
          next_link_content:
            content_tag :i, class: "fas fa-chevron-right" do
            end
        )

      assert result =~
               ~s(<a class="next" href="/pets?page=3&amp;page_size=10" ) <>
                 ~s(title="back">) <>
                 ~s(<i class="fas fa-chevron-right"></i></a>)
    end

    test "disables next link if on last page" do
      result = render_pagination(build(:meta_on_last_page))

      assert result =~
               ~s(<span class="pagination-next" disabled="disabled">) <>
                 ~s(Next</span>)
    end

    test "allows to overwrite next link attributes and content when disabled" do
      result =
        render_pagination(
          build(:meta_on_last_page),
          next_link_attrs: [class: "next", title: "no"],
          next_link_content:
            content_tag :i, class: "fas fa-chevron-right" do
            end
        )

      assert result =~
               ~s(<span class="next" disabled="disabled" title="no">) <>
                 ~s(<i class="fas fa-chevron-right"></i></span>)
    end

    test "renders page links" do
      result = render_pagination(build(:meta_on_second_page))

      assert result =~ ~s(<ul class="pagination-list">)

      assert result =~
               ~s(<li><a aria-label="Goto page 1" class="pagination-link" ) <>
                 ~s(href="/pets?page=1&amp;page_size=10">1</a></li>)

      assert result =~
               ~s(<li><a aria-current="page" aria-label="Goto page 2" ) <>
                 ~s(class="pagination-link is-current" ) <>
                 ~s(href="/pets?page=2&amp;page_size=10">2</a></li>)

      assert result =~
               ~s(<li><a aria-label="Goto page 3" class="pagination-link" ) <>
                 ~s(href="/pets?page=3&amp;page_size=10">3</a></li>)

      assert result =~ "</ul>"
    end

    test "doesn't render pagination links if set to hide" do
      result = render_pagination(build(:meta_on_second_page), page_links: :hide)
      refute result =~ "pagination-list"
    end

    test "allows to overwrite pagination list attributes" do
      result =
        render_pagination(
          build(:meta_on_first_page),
          pagination_list_attrs: [class: "p-list", title: "boop"]
        )

      assert result =~ "<ul class=\"p-list\" title=\"boop\">"
    end

    test "allows to overwrite pagination link attributes" do
      result =
        render_pagination(
          build(:meta_on_second_page),
          pagination_link_attrs: [class: "p-link", beep: "boop"]
        )

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-label="Goto page 1" beep="boop" ) <>
                 ~s(class="p-link" href="/pets?page=1&amp;page_size=10">) <>
                 ~s(1</a></li>)

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-current="page" ) <>
                 ~s(aria-label="Goto page 2" beep="boop" ) <>
                 ~s(class="p-link is-current" ) <>
                 ~s(href="/pets?page=2&amp;page_size=10">2</a></li>)
    end

    test "allows to overwrite pagination link aria label" do
      result =
        render_pagination(
          build(:meta_on_second_page),
          pagination_link_aria_label: &"On to page #{&1}"
        )

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-label="On to page 1" class="pagination-link" ) <>
                 ~s(href="/pets?page=1&amp;page_size=10">1</a></li>)

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-current="page" aria-label="On to page 2" ) <>
                 ~s(class="pagination-link is-current" ) <>
                 ~s(href="/pets?page=2&amp;page_size=10">2</a></li>)
    end

    test "adds order parameters to links" do
      result =
        render_pagination(
          build(:meta_on_second_page,
            flop: %Flop{
              order_by: [:fur_length, :curiosity],
              order_directions: [:asc, :desc]
            }
          )
        )

      expected_url = fn page ->
        ~s(/pets?page=#{page}&amp;page_size=10&amp;) <>
          ~s(order_directions[]=asc&amp;order_directions[]=desc&amp;) <>
          ~s(order_by[]=fur_length&amp;order_by[]=curiosity)
      end

      assert result =~
               ~s(<a class="pagination-previous" href=") <>
                 expected_url.(1) <> ~s(">Previous</a>)

      assert result =~
               ~s(<li><a aria-label="Goto page 1" class="pagination-link" ) <>
                 ~s(href=") <> expected_url.(1) <> ~s(">1</a></li>)

      assert result =~
               ~s(<a class="pagination-next" href=") <>
                 expected_url.(3) <> ~s(">Next</a>)
    end

    test "adds filter parameters to links" do
      result =
        render_pagination(
          build(:meta_on_second_page,
            flop: %Flop{
              filters: [
                %Flop.Filter{field: :fur_length, op: :>=, value: 5},
                %Flop.Filter{
                  field: :curiosity,
                  op: :in,
                  value: [:a_lot, :somewhat]
                }
              ]
            }
          )
        )

      expected_url = fn page ->
        ~s(/pets?page=#{page}&amp;page_size=10&amp;) <>
          ~s(filters[0][field]=fur_length&amp;) <>
          ~s(filters[0][op]=%3E%3D&amp;) <>
          ~s(filters[0][value]=5&amp;) <>
          ~s(filters[1][field]=curiosity&amp;) <>
          ~s(filters[1][op]=in&amp;) <>
          ~s(filters[1][value][]=a_lot&amp;) <>
          ~s(filters[1][value][]=somewhat)
      end

      assert result =~
               ~s(<a class="pagination-previous" href=") <>
                 expected_url.(1) <> ~s(">Previous</a>)

      assert result =~
               ~s(<li><a aria-label="Goto page 1" class="pagination-link" ) <>
                 ~s(href=") <> expected_url.(1) <> ~s(">1</a></li>)

      assert result =~
               ~s(<a class="pagination-next" href=") <>
                 expected_url.(3) <> ~s(">Next</a>)
    end

    test "does not render ellipsis if total pages <= max pages" do
      # max pages smaller than total pages
      result =
        render_pagination(build(:meta_on_second_page),
          page_links: {:ellipsis, 50}
        )

      refute result =~ "pagination-ellipsis"
      assert count_substrings(result, ~r/pagination-link/) == 5

      # max pages equal to total pages
      result =
        render_pagination(build(:meta_on_second_page),
          page_links: {:ellipsis, 5}
        )

      refute result =~ "pagination-ellipsis"
      assert count_substrings(result, ~r/pagination-link/) == 5
    end

    test "renders end ellipsis and last page link when on page 1" do
      # current page == 1
      result =
        render_pagination(build(:meta_on_first_page, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 1
      assert count_substrings(result, ~r/pagination-link/) == 6
      for i <- 1..5, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">20<")
    end

    test "renders start ellipsis and first page link when on last page" do
      # current page == last page
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 20, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 1
      assert count_substrings(result, ~r/pagination-link/) == 6
      for i <- 16..20, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">1<")
    end

    test "renders ellipses when on even page with even number of max pages" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 12, total_pages: 20),
          page_links: {:ellipsis, 6}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 2
      assert count_substrings(result, ~r/pagination-link/) == 8
      for i <- 10..15, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">1<")
      assert String.contains?(result, ">20<")
    end

    test "renders ellipses when on odd page with odd number of max pages" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 11, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 2
      assert count_substrings(result, ~r/pagination-link/) == 7
      for i <- 9..13, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">1<")
      assert String.contains?(result, ">20<")
    end

    test "renders ellipses when on even page with odd number of max pages" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 10, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 2
      assert count_substrings(result, ~r/pagination-link/) == 7
      for i <- 8..12, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">1<")
      assert String.contains?(result, ">20<")
    end

    test "renders ellipses when on odd page with even number of max pages" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 11, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 2
      assert count_substrings(result, ~r/pagination-link/) == 7
      for i <- 9..13, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">1<")
      assert String.contains?(result, ">20<")
    end

    test "renders end ellipsis when on page close to the beginning" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 2, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 1
      assert count_substrings(result, ~r/pagination-link/) == 6
      for i <- 1..5, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">20<")
    end

    test "renders start ellipsis when on page close to the end" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 18, total_pages: 20),
          page_links: {:ellipsis, 5}
        )

      assert count_substrings(result, ~r/pagination-ellipsis/) == 1
      assert count_substrings(result, ~r/pagination-link/) == 6
      for i <- 16..20, do: assert(String.contains?(result, ">#{i}<"))
      assert String.contains?(result, ">1<")
    end

    test "allows to overwrite ellipsis attributes and content" do
      result =
        render_pagination(
          build(:meta_on_first_page, current_page: 10, total_pages: 20),
          page_links: {:ellipsis, 5},
          ellipsis_attrs: [class: "dotdotdot", title: "dot"],
          ellipsis_content: "dot dot dot"
        )

      expected = ~r/<span class="dotdotdot" title="dot">dot dot dot<\/span>/
      assert count_substrings(result, expected) == 2
    end
  end
end
