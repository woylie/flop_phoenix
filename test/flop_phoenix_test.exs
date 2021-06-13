defmodule Flop.PhoenixTest do
  use ExUnit.Case
  use Phoenix.HTML

  import Flop.Phoenix
  import Flop.Phoenix.Factory
  import Phoenix.HTML.Safe, only: [to_iodata: 1]

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
    |> to_iodata()
    |> raw()
    |> safe_to_string()
  end

  defp render_table(assigns) do
    assigns
    |> table()
    |> to_iodata()
    |> raw()
    |> safe_to_string()
  end

  defp route_helper(%{}, path, query) do
    URI.to_string(%URI{path: "/#{path}", query: Query.encode(query)})
  end

  describe "pagination/4" do
    test "renders pagination wrapper" do
      result =
        :meta_on_first_page |> build() |> render_pagination() |> String.trim()

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
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page_size=10">Previous</a>)
    end

    test "merges query parameters into existing parameters" do
      result =
        :meta_on_second_page
        |> build()
        |> pagination(
          &route_helper/3,
          @route_helper_opts ++ [[category: "dinosaurs"]]
        )
        |> to_iodata()
        |> raw()
        |> safe_to_string()

      assert result =~
               ~s(<a class="pagination-previous" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?category=dinosaurs&amp;page_size=10">Previous</a>)
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
               ~s(<a class="prev" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page_size=10" ) <>
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
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
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
               ~s(<a class="next" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page=3&amp;page_size=10" ) <>
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
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page_size=10">1</a></li>)

      assert result =~
               ~s(<li><a aria-current="page" aria-label="Goto page 2" ) <>
                 ~s(class="pagination-link is-current" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page=2&amp;page_size=10">2</a></li>)

      assert result =~
               ~s(<li><a aria-label="Goto page 3" class="pagination-link" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
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
                 ~s(<a aria-label="Goto page 1" beep="boop" class="p-link" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page_size=10">) <>
                 ~s(1</a></li>)

      # current link attributes are unchanged
      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-current="page" ) <>
                 ~s(aria-label="Goto page 2" ) <>
                 ~s(class="pagination-link is-current" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page=2&amp;page_size=10">2</a></li>)
    end

    test "allows to overwrite current attributes" do
      result =
        render_pagination(
          build(:meta_on_second_page),
          current_link_attrs: [class: "link is-active", beep: "boop"]
        )

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-label="Goto page 1" class="pagination-link" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page_size=10">) <>
                 ~s(1</a></li>)

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-current="page" ) <>
                 ~s(aria-label="Goto page 2" beep="boop" ) <>
                 ~s(class="link is-active" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
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
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page_size=10">1</a></li>)

      assert result =~
               ~s(<li>) <>
                 ~s(<a aria-current="page" aria-label="On to page 2" ) <>
                 ~s(class="pagination-link is-current" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href="/pets?page=2&amp;page_size=10">2</a></li>)
    end

    test "adds order parameters to links" do
      result =
        render_pagination(
          build(:meta_on_second_page,
            flop: %Flop{
              order_by: [:fur_length, :curiosity],
              order_directions: [:asc, :desc],
              page: 2,
              page_size: 10
            }
          )
        )

      expected_url = fn page ->
        default =
          ~s(order_directions[]=asc&amp;order_directions[]=desc&amp;) <>
            ~s(order_by[]=fur_length&amp;order_by[]=curiosity&amp;) <>
            ~s(page_size=10)

        if page == 1,
          do: "/pets?" <> default,
          else: ~s(/pets?page=#{page}&amp;) <> default
      end

      assert result =~
               ~s(<a class="pagination-previous" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href=") <>
                 expected_url.(1) <> ~s(">Previous</a>)

      assert result =~
               ~s(<li><a aria-label="Goto page 1" class="pagination-link" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href=") <> expected_url.(1) <> ~s(">1</a></li>)

      assert result =~
               ~s(<a class="pagination-next" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" href=") <>
                 expected_url.(3) <> ~s(">Next</a>)
    end

    test "adds filter parameters to links" do
      result =
        render_pagination(
          build(:meta_on_second_page,
            flop: %Flop{
              page: 2,
              page_size: 10,
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
        default =
          ~s(filters[0][field]=fur_length&amp;) <>
            ~s(filters[0][op]=%3E%3D&amp;) <>
            ~s(filters[0][value]=5&amp;) <>
            ~s(filters[1][field]=curiosity&amp;) <>
            ~s(filters[1][op]=in&amp;) <>
            ~s(filters[1][value][]=a_lot&amp;) <>
            ~s(filters[1][value][]=somewhat) <>
            ~s(&amp;page_size=10)

        if page == 1,
          do: "/pets?" <> default,
          else: ~s(/pets?page=#{page}&amp;) <> default
      end

      assert result =~
               ~s(<a class="pagination-previous" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" href=") <>
                 expected_url.(1) <> ~s(">Previous</a>)

      assert result =~
               ~s(<li><a aria-label="Goto page 1" class="pagination-link" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" ) <>
                 ~s(href=") <> expected_url.(1) <> ~s(">1</a></li>)

      assert result =~
               ~s(<a class="pagination-next" ) <>
                 ~s(data-phx-link="patch" data-phx-link-state="push" href=") <>
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

    @tag :this
    test "always uses page/page_size" do
      result =
        render_pagination(
          build(:meta_on_second_page,
            flop: %Flop{limit: 2, page: 2, page_size: nil, offset: 3}
          )
        )

      assert result =~ "page_size=2"
      refute result =~ "limit=2"
      refute result =~ "offset=3"
    end
  end

  describe "table/1" do
    setup do
      %{
        assigns: %{
          headers: ["name"],
          items: [%{name: "George"}],
          meta: %Flop.Meta{flop: %Flop{}},
          path_helper: &route_helper/3,
          path_helper_args: [%{}, :index],
          opts: [],
          row_func: fn %{name: name}, _opts -> [name] end
        }
      }
    end

    test "allows to set table attributes", %{assigns: assigns} do
      assert render_table(%{assigns | opts: []}) =~ ~s(<table>)
      opts = [table_attrs: [class: "funky-table"]]

      assert render_table(%{assigns | opts: opts}) =~
               ~s(<table class="funky-table">)
    end

    test "optionally adds a table container", %{assigns: assigns} do
      refute render_table(%{assigns | opts: []}) =~
               ~s(<div class="table-container">)

      assert render_table(%{assigns | opts: [container: true]}) =~
               ~s(<div class="table-container">)
    end

    test "allows to set container attributes", %{assigns: assigns} do
      opts = [container: true, container_attrs: [class: "container", id: "a"]]

      assert render_table(%{assigns | opts: opts}) =~
               ~s(<div class="container" id="a">)
    end

    test "allows to set tr and td classes", %{assigns: assigns} do
      opts = [
        thead_tr_attrs: [class: "mungo"],
        thead_th_attrs: [class: "bean"],
        tbody_tr_attrs: [class: "salt"],
        tbody_td_attrs: [class: "tolerance"]
      ]

      html = render_table(%{assigns | opts: opts})

      assert html =~ ~s(<tr class="mungo"><th)
      assert html =~ ~s(<th class="bean">)
      assert html =~ ~s(<tr class="salt"><td)
      assert html =~ ~s(<td class="tolerance">)
    end

    test "doesn't render table if items list is empty", %{assigns: assigns} do
      refute render_table(%{assigns | items: []}) =~ ~s(<table)
    end

    test "displays headers without sorting function", %{assigns: assigns} do
      html = render_table(%{assigns | headers: ["Name", "Age"]})
      assert html =~ ~s(<th>Name</th>)
      assert html =~ ~s(<th>Age</th>)
    end

    test "displays headers with sorting function", %{assigns: assigns} do
      html = render_table(%{assigns | headers: ["Name", {"Age", :age}]})
      assert html =~ ~s(<th>Name</th>)

      assert html =~
               ~s(<a data-phx-link="patch" data-phx-link-state="push" href="/index?order_directions[]=asc&amp;order_by[]=age">Age</a>)
    end

    test "checks for sortability if for option is set", %{assigns: assigns} do
      # without :for option
      html =
        render_table(%{
          assigns
          | headers: [{"Name", :name}, {"Age", :age}, {"Species", :species}]
        })

      assert html =~ ~s(Name</a>)
      assert html =~ ~s(Age</a>)
      assert html =~ ~s(Species</a>)

      # with :for option
      html =
        render_table(%{
          assigns
          | headers: [{"Name", :name}, {"Age", :age}, {"Species", :species}],
            opts: [for: Flop.Phoenix.Pet]
        })

      assert html =~ ~s(Name</a>)
      assert html =~ ~s(Age</a>)
      refute html =~ ~s(Species</a>)
    end

    test "renders order direction symbol", %{assigns: assigns} do
      refute render_table(%{
               assigns
               | meta: %Flop.Meta{
                   flop: %Flop{order_by: [:name], order_directions: [:asc]}
                 }
             }) =~ ~s(<span class="order-direction")

      assert render_table(%{
               assigns
               | headers: [{"Name", :name}],
                 meta: %Flop.Meta{
                   flop: %Flop{order_by: [:name], order_directions: [:asc]}
                 }
             }) =~ ~s(<span class="order-direction">▴</span>)

      assert render_table(%{
               assigns
               | headers: [{"Name", :name}],
                 meta: %Flop.Meta{
                   flop: %Flop{order_by: [:name], order_directions: [:desc]}
                 }
             }) =~ ~s(<span class="order-direction">▾</span>)
    end

    test "allows to set symbol class", %{assigns: assigns} do
      meta = %Flop.Meta{
        flop: %Flop{order_by: [:name], order_directions: [:asc]}
      }

      opts = [symbol_attrs: [class: "other-class"]]

      assert render_table(%{
               assigns
               | headers: [{"Name", :name}],
                 meta: meta,
                 opts: opts
             }) =~ ~s(<span class="other-class")
    end

    test "allows to override default symbols", %{assigns: assigns} do
      assert render_table(%{
               assigns
               | headers: [{"Name", :name}],
                 meta: %Flop.Meta{
                   flop: %Flop{order_by: [:name], order_directions: [:asc]}
                 },
                 opts: [symbol_asc: "asc"]
             }) =~ ~s(<span class="order-direction">asc</span>)

      assert render_table(%{
               assigns
               | headers: [{"Name", :name}],
                 meta: %Flop.Meta{
                   flop: %Flop{order_by: [:name], order_directions: [:desc]}
                 },
                 opts: [symbol_desc: "desc"]
             }) =~ ~s(<span class="order-direction">desc</span>)
    end

    test "renders all items", %{assigns: assigns} do
      html =
        render_table(%{
          assigns
          | items: [%{name: "George", age: 8}, %{name: "Barbara", age: 2}],
            opts: [appendix: "-chan"],
            row_func: fn %{age: age, name: name}, opts ->
              [name <> opts[:appendix], age]
            end
        })

      assert html =~ ~s(<td>George-chan</td>)
      assert html =~ ~s(<td>8</td>)
      assert html =~ ~s(<td>Barbara-chan</td>)
      assert html =~ ~s(<td>2</td>)
    end

    test "renders notice if item list is empty", %{assigns: assigns} do
      html = render_table(%{assigns | items: []})
      assert String.trim(html) == "<p>No results.</p>"
    end

    test "allows to set no_results_content", %{assigns: assigns} do
      opts = [no_results_content: ~E"<div>Nothing!</div>"]
      html = render_table(%{assigns | items: [], opts: opts})
      assert String.trim(html) == "<div>Nothing!</div>"
    end
  end

  describe "to_query/2" do
    test "does not add empty values" do
      refute %Flop{limit: nil} |> to_query() |> Keyword.has_key?(:limit)
      refute %Flop{order_by: []} |> to_query() |> Keyword.has_key?(:order_by)
      refute %Flop{filters: %{}} |> to_query() |> Keyword.has_key?(:filters)
    end

    test "does not add params for first page/offset" do
      refute %Flop{page: 1} |> to_query() |> Keyword.has_key?(:page)
      refute %Flop{offset: 0} |> to_query() |> Keyword.has_key?(:offset)
    end

    test "does not add limit/page_size if it matches default" do
      opts = [default_limit: 20]

      assert %Flop{page_size: 10}
             |> to_query(opts)
             |> Keyword.has_key?(:page_size)

      assert %Flop{limit: 10}
             |> to_query(opts)
             |> Keyword.has_key?(:limit)

      refute %Flop{page_size: 20}
             |> to_query(opts)
             |> Keyword.has_key?(:page_size)

      refute %Flop{limit: 20}
             |> to_query(opts)
             |> Keyword.has_key?(:limit)
    end

    test "does not order params if they match the default" do
      opts = [
        default_order: %{
          order_by: [:name, :age],
          order_directions: [:asc, :desc]
        }
      ]

      # order_by does not match default
      query =
        to_query(
          %Flop{order_by: [:name, :email], order_directions: [:asc, :desc]},
          opts
        )

      assert Keyword.has_key?(query, :order_by)
      assert Keyword.has_key?(query, :order_directions)

      # order_directions does not match default
      query =
        to_query(
          %Flop{order_by: [:name, :age], order_directions: [:desc, :desc]},
          opts
        )

      assert Keyword.has_key?(query, :order_by)
      assert Keyword.has_key?(query, :order_directions)

      # order_by and order_directions match default
      query =
        to_query(
          %Flop{order_by: [:name, :age], order_directions: [:asc, :desc]},
          opts
        )

      refute Keyword.has_key?(query, :order_by)
      refute Keyword.has_key?(query, :order_directions)
    end
  end
end
