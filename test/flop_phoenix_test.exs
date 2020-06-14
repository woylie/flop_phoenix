defmodule FlopPhoenixTest do
  use ExUnit.Case
  use Phoenix.HTML

  import FlopPhoenix
  import FlopPhoenix.Factory

  doctest FlopPhoenix

  @route_helper_opts [%{}, :pets]

  defp route_helper(%{}, path, query) do
    URI.to_string(%URI{path: "/#{path}", query: URI.encode_query(query)})
  end

  describe "pagination/4" do
    test "renders pagination wrapper" do
      result =
        build(:meta)
        |> pagination(&route_helper/3, @route_helper_opts)
        |> safe_to_string()

      assert String.starts_with?(
               result,
               "<nav aria-label=\"pagination\" class=\"pagination\" role=\"navigation\">"
             )

      assert String.ends_with?(result, "</nav>")
    end

    test "allows to overwrite wrapper class" do
      result =
        build(:meta)
        |> pagination(&route_helper/3, @route_helper_opts, wrapper_class: "boo")
        |> safe_to_string()

      assert result =~
               "<nav aria-label=\"pagination\" class=\"boo\" role=\"navigation\">"
    end

    test "renders previous link" do
      meta =
        build(:meta,
          current_page: 2,
          current_offset: 10,
          has_previous_page?: true,
          previous_page: 1,
          previous_offset: 0
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts)
        |> safe_to_string()

      assert result =~
               "<a class=\"pagination-previous\" href=\"/pets?page=1&amp;page_size=10\">Previous</a>"
    end

    test "allows to overwrite previous link class and label" do
      meta =
        build(:meta,
          current_page: 2,
          current_offset: 10,
          has_previous_page?: true,
          previous_page: 1,
          previous_offset: 0
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts,
          previous_link_class: "prev",
          previous_link_content:
            content_tag :i, class: "fas fa-chevron-left" do
            end
        )
        |> safe_to_string()

      assert result =~
               "<a class=\"prev\" href=\"/pets?page=1&amp;page_size=10\"><i class=\"fas fa-chevron-left\"></i></a>"
    end

    test "disables previous link if on first page" do
      meta =
        build(:meta,
          current_offset: 0,
          current_page: 1,
          has_previous_page?: false,
          previous_offset: nil,
          previous_page: nil
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts)
        |> safe_to_string()

      assert result =~
               "<span class=\"pagination-previous\" disabled=\"disabled\">Previous</span>"
    end

    test "allows to overwrite previous link class and label if disabled" do
      meta =
        build(:meta,
          current_offset: 0,
          current_page: 1,
          has_previous_page?: false,
          previous_offset: nil,
          previous_page: nil
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts,
          previous_link_class: "prev",
          previous_link_content: "Prev"
        )
        |> safe_to_string()

      assert result =~
               "<span class=\"prev\" disabled=\"disabled\">Prev</span>"
    end

    test "renders next link" do
      meta =
        build(:meta,
          current_page: 2,
          current_offset: 10,
          has_next_page?: true,
          next_page: 3,
          next_offset: 20
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts)
        |> safe_to_string()

      assert result =~
               "<a class=\"pagination-next\" href=\"/pets?page=3&amp;page_size=10\">Next</a>"
    end

    test "allows to overwrite next link class and label" do
      meta =
        build(:meta,
          current_page: 2,
          current_offset: 10,
          has_next_page?: true,
          next_page: 3,
          next_offset: 20
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts,
          next_link_class: "next",
          next_link_content:
            content_tag :i, class: "fas fa-chevron-right" do
            end
        )
        |> safe_to_string()

      assert result =~
               "<a class=\"next\" href=\"/pets?page=3&amp;page_size=10\"><i class=\"fas fa-chevron-right\"></i></a>"
    end

    test "disables next link if on last page" do
      meta =
        build(:meta,
          current_offset: 40,
          current_page: 5,
          has_next_page?: false,
          next_offset: nil,
          next_page: nil
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts)
        |> safe_to_string()

      assert result =~
               "<span class=\"pagination-next\" disabled=\"disabled\">Next</span>"
    end

    test "allows to overwrite next link class and label when disabled" do
      meta =
        build(:meta,
          current_offset: 40,
          current_page: 5,
          has_next_page?: false,
          next_offset: nil,
          next_page: nil
        )

      result =
        meta
        |> pagination(&route_helper/3, @route_helper_opts,
          next_link_class: "next",
          next_link_content:
            content_tag :i, class: "fas fa-chevron-right" do
            end
        )
        |> safe_to_string()

      assert result =~
               "<span class=\"next\" disabled=\"disabled\"><i class=\"fas fa-chevron-right\"></i></span>"
    end
  end
end
