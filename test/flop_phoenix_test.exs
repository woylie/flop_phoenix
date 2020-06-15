defmodule FlopPhoenixTest do
  use ExUnit.Case
  use Phoenix.HTML

  import FlopPhoenix
  import FlopPhoenix.Factory

  alias Flop.Meta

  doctest FlopPhoenix

  @route_helper_opts [%{}, :pets]

  defp render_pagination(%Meta{} = meta, opts \\ []) do
    meta
    |> pagination(&route_helper/3, @route_helper_opts, opts)
    |> safe_to_string()
  end

  defp route_helper(%{}, path, query) do
    URI.to_string(%URI{path: "/#{path}", query: URI.encode_query(query)})
  end

  describe "pagination/4" do
    test "renders pagination wrapper" do
      result = render_pagination(build(:meta))

      assert String.starts_with?(
               result,
               "<nav aria-label=\"pagination\" class=\"pagination\" role=\"navigation\">"
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
      result = render_pagination(build(:meta), wrapper_class: "boo")

      assert result =~
               "<nav aria-label=\"pagination\" class=\"boo\" role=\"navigation\">"
    end

    test "renders previous link" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            current_offset: 10,
            has_previous_page?: true,
            previous_page: 1,
            previous_offset: 0
          )
        )

      assert result =~
               "<a class=\"pagination-previous\" href=\"/pets?page=1&amp;page_size=10\">Previous</a>"
    end

    test "allows to overwrite previous link class and label" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            current_offset: 10,
            has_previous_page?: true,
            previous_page: 1,
            previous_offset: 0
          ),
          previous_link_class: "prev",
          previous_link_content:
            content_tag :i, class: "fas fa-chevron-left" do
            end
        )

      assert result =~
               "<a class=\"prev\" href=\"/pets?page=1&amp;page_size=10\"><i class=\"fas fa-chevron-left\"></i></a>"
    end

    test "disables previous link if on first page" do
      result =
        render_pagination(
          build(:meta,
            current_offset: 0,
            current_page: 1,
            has_previous_page?: false,
            previous_offset: nil,
            previous_page: nil
          )
        )

      assert result =~
               "<span class=\"pagination-previous\" disabled=\"disabled\">Previous</span>"
    end

    test "allows to overwrite previous link class and label if disabled" do
      result =
        render_pagination(
          build(:meta,
            current_offset: 0,
            current_page: 1,
            has_previous_page?: false,
            previous_offset: nil,
            previous_page: nil
          ),
          previous_link_class: "prev",
          previous_link_content: "Prev"
        )

      assert result =~
               "<span class=\"prev\" disabled=\"disabled\">Prev</span>"
    end

    test "renders next link" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            current_offset: 10,
            has_next_page?: true,
            next_page: 3,
            next_offset: 20
          )
        )

      assert result =~
               "<a class=\"pagination-next\" href=\"/pets?page=3&amp;page_size=10\">Next</a>"
    end

    test "allows to overwrite next link class and label" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            current_offset: 10,
            has_next_page?: true,
            next_page: 3,
            next_offset: 20
          ),
          next_link_class: "next",
          next_link_content:
            content_tag :i, class: "fas fa-chevron-right" do
            end
        )

      assert result =~
               "<a class=\"next\" href=\"/pets?page=3&amp;page_size=10\"><i class=\"fas fa-chevron-right\"></i></a>"
    end

    test "disables next link if on last page" do
      result =
        render_pagination(
          build(:meta,
            current_offset: 40,
            current_page: 5,
            has_next_page?: false,
            next_offset: nil,
            next_page: nil
          )
        )

      assert result =~
               "<span class=\"pagination-next\" disabled=\"disabled\">Next</span>"
    end

    test "allows to overwrite next link class and label when disabled" do
      result =
        render_pagination(
          build(:meta,
            current_offset: 40,
            current_page: 5,
            has_next_page?: false,
            next_offset: nil,
            next_page: nil
          ),
          next_link_class: "next",
          next_link_content:
            content_tag :i, class: "fas fa-chevron-right" do
            end
        )

      assert result =~
               "<span class=\"next\" disabled=\"disabled\"><i class=\"fas fa-chevron-right\"></i></span>"
    end

    test "renders page links" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            has_next_page?: true,
            has_previous_page?: true,
            next_page: 3,
            page_size: 10,
            previous_page: 1,
            total_pages: 3
          )
        )

      assert result =~ "<ul class=\"pagination-list\">"

      assert result =~
               "<li><a aria-label=\"Goto page 1\" class=\"pagination-link\" href=\"/pets?page=1&amp;page_size=10\">1</a></li>"

      assert result =~
               "<li><a aria-current=\"page\" aria-label=\"Goto page 2\" class=\"pagination-link is-current\" href=\"/pets?page=2&amp;page_size=10\">2</a></li>"

      assert result =~
               "<li><a aria-label=\"Goto page 3\" class=\"pagination-link\" href=\"/pets?page=3&amp;page_size=10\">3</a></li>"

      assert result =~ "</ul>"
    end

    test "allows to overwrite pagination list class" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            has_next_page?: true,
            has_previous_page?: true,
            next_page: 3,
            page_size: 10,
            previous_page: 1,
            total_pages: 3
          ),
          pagination_list_class: "p-list"
        )

      assert result =~ "<ul class=\"p-list\">"
    end

    test "allows to overwrite pagination link class" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            has_next_page?: true,
            has_previous_page?: true,
            next_page: 3,
            page_size: 10,
            previous_page: 1,
            total_pages: 3
          ),
          pagination_link_class: "p-link"
        )

      assert result =~
               "<li><a aria-label=\"Goto page 1\" class=\"p-link\" href=\"/pets?page=1&amp;page_size=10\">1</a></li>"

      assert result =~
               "<li><a aria-current=\"page\" aria-label=\"Goto page 2\" class=\"p-link is-current\" href=\"/pets?page=2&amp;page_size=10\">2</a></li>"
    end

    test "allows to overwrite pagination link aria label" do
      result =
        render_pagination(
          build(:meta,
            current_page: 2,
            has_next_page?: true,
            has_previous_page?: true,
            next_page: 3,
            page_size: 10,
            previous_page: 1,
            total_pages: 3
          ),
          pagination_link_aria_label: &"On to page #{&1}"
        )

      assert result =~
               "<li><a aria-label=\"On to page 1\" class=\"pagination-link\" href=\"/pets?page=1&amp;page_size=10\">1</a></li>"

      assert result =~
               "<li><a aria-current=\"page\" aria-label=\"On to page 2\" class=\"pagination-link is-current\" href=\"/pets?page=2&amp;page_size=10\">2</a></li>"
    end
  end
end
