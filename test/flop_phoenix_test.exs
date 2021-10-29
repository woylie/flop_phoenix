defmodule Flop.PhoenixTest do
  use ExUnit.Case
  use Phoenix.Component
  use Phoenix.HTML

  import Flop.Phoenix
  import Flop.Phoenix.Factory
  import Phoenix.LiveViewTest

  alias Flop.Phoenix.Pet
  alias Plug.Conn.Query

  doctest Flop.Phoenix, import: true

  @route_helper_opts [%{}, :pets]

  defp render_pagination(assigns) do
    assigns =
      assigns
      |> Keyword.put(:__changed__, nil)
      |> Keyword.put_new(
        :path_helper,
        {__MODULE__, :route_helper, @route_helper_opts}
      )

    (&pagination/1)
    |> render_component(assigns)
    |> Floki.parse_fragment!()
  end

  defp render_table(assigns \\ [], component \\ &test_table/1) do
    assigns = Keyword.put(assigns, :__changed__, nil)

    component
    |> render_component(assigns)
    |> Floki.parse_fragment!()
  end

  defp test_table(assigns) do
    assigns =
      assigns
      |> assign_new(:for, fn -> nil end)
      |> assign_new(:event, fn -> nil end)
      |> assign_new(:items, fn ->
        [%{name: "George", email: "george@george.pet", age: 8, species: "dog"}]
      end)
      |> assign_new(:meta, fn -> %Flop.Meta{flop: %Flop{}} end)
      |> assign_new(:path_helper, fn ->
        {__MODULE__, :route_helper, @route_helper_opts}
      end)
      |> assign_new(:opts, fn -> [] end)
      |> assign_new(:target, fn -> nil end)

    ~H"""
    <Flop.Phoenix.table
      for={@for}
      event={@event}
      items={@items}
      meta={@meta}
      opts={@opts}
      path_helper={@path_helper}
      target={@target}
    >
      <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
      <:col let={pet} label="Email" field={:email}><%= pet.email %></:col>
      <:col let={pet} label="Age"><%= pet.age %></:col>
      <:col let={pet} label="Species" field={:species}><%= pet.species %></:col>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_foot(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George"}]}
      meta={%Flop.Meta{flop: %Flop{}}}
    >
      <:col let={pet} label="Name" field={:name}><%= pet.name %></:col>
      <:foot>
        <tr><td>snap</td></tr>
      </:foot>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_html_header(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George"}]}
      meta={%Flop.Meta{flop: %Flop{}}}
    >
      <:col
        let={pet}
        label={{:safe, "<span>Hello</span>"}}
        field={:name}
      >
        <%= pet.name %>
      </:col>
    </Flop.Phoenix.table>
    """
  end

  def route_helper(%{}, action, query) do
    URI.to_string(%URI{path: "/#{action}", query: Query.encode(query)})
  end

  describe "pagination/4" do
    test "renders pagination wrapper" do
      html = render_pagination(meta: build(:meta_on_first_page))
      wrapper = Floki.find(html, "nav")

      assert Floki.attribute(wrapper, "aria-label") == ["pagination"]
      assert Floki.attribute(wrapper, "class") == ["pagination"]
      assert Floki.attribute(wrapper, "role") == ["navigation"]
    end

    test "does not render anything if there is only one page" do
      assert render_pagination(meta: build(:meta_one_page)) == []
    end

    test "does not render anything if there are no results" do
      assert render_pagination(meta: build(:meta_no_results)) == []
    end

    test "allows to overwrite wrapper class" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page),
          opts: [wrapper_attrs: [class: "boo"]]
        )

      wrapper = Floki.find(html, "nav")

      assert Floki.attribute(wrapper, "aria-label") == ["pagination"]
      assert Floki.attribute(wrapper, "class") == ["boo"]
      assert Floki.attribute(wrapper, "role") == ["navigation"]
    end

    test "allows to add attributes to wrapper" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page),
          opts: [wrapper_attrs: [title: "paginate"]]
        )

      wrapper = Floki.find(html, "nav")

      assert Floki.attribute(wrapper, "aria-label") == ["pagination"]
      assert Floki.attribute(wrapper, "class") == ["pagination"]
      assert Floki.attribute(wrapper, "role") == ["navigation"]
      assert Floki.attribute(wrapper, "title") == ["paginate"]
    end

    test "renders previous link" do
      html = render_pagination(meta: build(:meta_on_second_page))
      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "class") == ["pagination-previous"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]
    end

    test "supports a function/args tuple as path_helper" do
      html =
        render_pagination(
          path_helper: {&route_helper/3, @route_helper_opts},
          meta: build(:meta_on_second_page)
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]
    end

    test "renders previous link when using click event handling" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path_helper: nil
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "class") == ["pagination-previous"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-page") == ["1"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "adds phx-target to previous link" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path_helper: nil,
          target: "here"
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "phx-target") == ["here"]
    end

    test "merges query parameters into existing parameters" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          path_helper:
            {&route_helper/3, @route_helper_opts ++ [[category: "dinosaurs"]]},
          opts: []
        )

      assert [previous] = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(previous, "class") == ["pagination-previous"]
      assert Floki.attribute(previous, "data-phx-link") == ["patch"]
      assert Floki.attribute(previous, "data-phx-link-state") == ["push"]

      assert Floki.attribute(previous, "href") == [
               "/pets?category=dinosaurs&page_size=10"
             ]
    end

    test "allows to overwrite previous link attributes and content" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [
            previous_link_attrs: [class: "prev", title: "p-p-previous"],
            previous_link_content: tag(:i, class: "fas fa-chevron-left")
          ]
        )

      assert [link] = Floki.find(html, "a[title='p-p-previous']")
      assert Floki.attribute(link, "class") == ["prev"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]

      assert link |> Floki.children() |> Floki.raw_html() ==
               "<i class=\"fas fa-chevron-left\"></i>"
    end

    test "disables previous link if on first page" do
      html = render_pagination(meta: build(:meta_on_first_page))
      previous_link = Floki.find(html, "span:fl-contains('Previous')")

      assert Floki.attribute(previous_link, "class") == ["pagination-previous"]
      assert Floki.attribute(previous_link, "disabled") == ["disabled"]
    end

    test "disables previous link if on first page when using click handlers" do
      html =
        render_pagination(
          event: "e",
          meta: build(:meta_on_first_page),
          path_helper: nil
        )

      previous_link = Floki.find(html, "span:fl-contains('Previous')")

      assert Floki.attribute(previous_link, "class") == ["pagination-previous"]
      assert Floki.attribute(previous_link, "disabled") == ["disabled"]
    end

    test "allows to overwrite previous link class and content if disabled" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page),
          opts: [
            previous_link_attrs: [class: "prev", title: "no"],
            previous_link_content: "Prev"
          ]
        )

      previous_link = Floki.find(html, "span:fl-contains('Prev')")

      assert Floki.attribute(previous_link, "class") == ["prev"]
      assert Floki.attribute(previous_link, "disabled") == ["disabled"]
      assert Floki.attribute(previous_link, "title") == ["no"]
      assert Floki.text(previous_link) == "Prev"
    end

    test "renders next link" do
      link =
        [meta: build(:meta_on_second_page)]
        |> render_pagination()
        |> Floki.find("a:fl-contains('Next')")

      assert Floki.attribute(link, "class") == ["pagination-next"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=3&page_size=10"]
    end

    test "renders next link when using click event handling" do
      link =
        [event: "paginate", meta: build(:meta_on_second_page), path_helper: nil]
        |> render_pagination()
        |> Floki.find("a:fl-contains('Next')")

      assert Floki.attribute(link, "class") == ["pagination-next"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-page") == ["3"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "adds phx-target to next link" do
      link =
        [
          event: "paginate",
          meta: build(:meta_on_second_page),
          path_helper: nil,
          target: "here"
        ]
        |> render_pagination()
        |> Floki.find("a:fl-contains('Next')")

      assert Floki.attribute(link, "phx-target") == ["here"]
    end

    test "allows to overwrite next link attributes and content" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [
            next_link_attrs: [class: "next", title: "n-n-next"],
            next_link_content: tag(:i, class: "fas fa-chevron-right")
          ]
        )

      assert [link] = Floki.find(html, "a[title='n-n-next']")
      assert Floki.attribute(link, "class") == ["next"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=3&page_size=10"]

      assert link |> Floki.children() |> Floki.raw_html() ==
               "<i class=\"fas fa-chevron-right\"></i>"
    end

    test "disables next link if on last page" do
      next =
        [meta: build(:meta_on_last_page)]
        |> render_pagination()
        |> Floki.find("span:fl-contains('Next')")

      assert Floki.attribute(next, "class") == ["pagination-next"]
      assert Floki.attribute(next, "disabled") == ["disabled"]
      assert Floki.attribute(next, "href") == []
    end

    test "renders next link on last page when using click event handling" do
      next =
        [event: "paginate", meta: build(:meta_on_last_page), path_helper: nil]
        |> render_pagination()
        |> Floki.find("span:fl-contains('Next')")

      assert Floki.attribute(next, "class") == ["pagination-next"]
      assert Floki.attribute(next, "disabled") == ["disabled"]
      assert Floki.attribute(next, "href") == []
    end

    test "allows to overwrite next link attributes and content when disabled" do
      next_link =
        [
          meta: build(:meta_on_last_page),
          opts: [
            next_link_attrs: [class: "next", title: "no"],
            next_link_content: "N-n-next"
          ]
        ]
        |> render_pagination()
        |> Floki.find("span:fl-contains('N-n-next')")

      assert Floki.attribute(next_link, "class") == ["next"]
      assert Floki.attribute(next_link, "disabled") == ["disabled"]
      assert Floki.attribute(next_link, "title") == ["no"]
    end

    test "renders page links" do
      html = render_pagination(meta: build(:meta_on_second_page))

      assert [_] = Floki.find(html, "ul[class='pagination-links']")

      assert [link] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(link, "class") == ["pagination-link"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]
      assert Floki.text(link) == "1"

      assert [link] = Floki.find(html, "a[aria-label='Go to page 2']")
      assert Floki.attribute(link, "class") == ["pagination-link is-current"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=2&page_size=10"]
      assert Floki.text(link) == "2"

      assert [link] = Floki.find(html, "a[aria-label='Go to page 3']")
      assert Floki.attribute(link, "class") == ["pagination-link"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=3&page_size=10"]
      assert Floki.text(link) == "3"
    end

    test "renders page links when using click event handling" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path_helper: nil
        )

      assert [link] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(link, "href") == ["#"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-page") == ["1"]
      assert Floki.text(link) == "1"
    end

    test "adds phx-target to page link" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          path_helper: nil,
          event: "paginate",
          target: "here"
        )

      assert [link] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(link, "phx-target") == ["here"]
    end

    test "doesn't render pagination links if set to hide" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [page_links: :hide]
        )

      assert Floki.find(html, ".pagination-links") == []
    end

    test "doesn't render pagination links if set to hide when passing event" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [page_links: :hide, event: "paginate"]
        )

      assert Floki.find(html, ".pagination-links") == []
    end

    test "allows to overwrite pagination list attributes" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page),
          opts: [pagination_list_attrs: [class: "p-list", title: "boop"]]
        )

      assert [list] = Floki.find(html, "ul.p-list")
      assert Floki.attribute(list, "title") == ["boop"]
    end

    test "allows to overwrite pagination link attributes" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [pagination_link_attrs: [class: "p-link", beep: "boop"]]
        )

      assert [link] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(link, "beep") == ["boop"]
      assert Floki.attribute(link, "class") == ["p-link"]

      # current link attributes are unchanged
      assert [link] = Floki.find(html, "a[aria-label='Go to page 2']")
      assert Floki.attribute(link, "beep") == []
      assert Floki.attribute(link, "class") == ["pagination-link is-current"]
    end

    test "allows to overwrite current attributes" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [current_link_attrs: [class: "link is-active", beep: "boop"]]
        )

      assert [link] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(link, "class") == ["pagination-link"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]
      assert Floki.text(link) == "1"

      assert [link] = Floki.find(html, "a[aria-label='Go to page 2']")
      assert Floki.attribute(link, "beep") == ["boop"]
      assert Floki.attribute(link, "class") == ["link is-active"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=2&page_size=10"]
      assert Floki.text(link) == "2"
    end

    test "allows to overwrite pagination link aria label" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          opts: [pagination_link_aria_label: &"On to page #{&1}"]
        )

      assert [link] = Floki.find(html, "a[aria-label='On to page 1']")
      assert Floki.attribute(link, "class") == ["pagination-link"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]
      assert Floki.text(link) == "1"

      assert [link] = Floki.find(html, "a[aria-label='On to page 2']")
      assert Floki.attribute(link, "class") == ["pagination-link is-current"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=2&page_size=10"]
      assert Floki.text(link) == "2"
    end

    test "adds order parameters to links" do
      html =
        render_pagination(
          meta:
            build(
              :meta_on_second_page,
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
          ~s(order_directions[]=asc&order_directions[]=desc&) <>
            ~s(order_by[]=fur_length&order_by[]=curiosity&) <>
            ~s(page_size=10)

        if page == 1,
          do: "/pets?" <> default,
          else: ~s(/pets?page=#{page}&) <> default
      end

      assert [previous] = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(previous, "class") == ["pagination-previous"]
      assert Floki.attribute(previous, "data-phx-link") == ["patch"]
      assert Floki.attribute(previous, "data-phx-link-state") == ["push"]
      assert Floki.attribute(previous, "href") == [expected_url.(1)]

      assert [one] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(one, "class") == ["pagination-link"]
      assert Floki.attribute(one, "data-phx-link") == ["patch"]
      assert Floki.attribute(one, "data-phx-link-state") == ["push"]
      assert Floki.attribute(one, "href") == [expected_url.(1)]

      assert [next] = Floki.find(html, "a:fl-contains('Next')")
      assert Floki.attribute(next, "class") == ["pagination-next"]
      assert Floki.attribute(next, "data-phx-link") == ["patch"]
      assert Floki.attribute(next, "data-phx-link-state") == ["push"]
      assert Floki.attribute(next, "href") == [expected_url.(3)]
    end

    test "hides default order and limit" do
      html =
        render_pagination(
          for: Pet,
          meta:
            build(
              :meta_on_second_page,
              flop: %Flop{
                page_size: 20,
                order_by: [:name],
                order_directions: [:asc]
              }
            )
        )

      assert [prev] = Floki.find(html, "a:fl-contains('Previous')")
      assert [href] = Floki.attribute(prev, "href")

      refute href =~ "page_size="
      refute href =~ "order_by[]="
      refute href =~ "order_directions[]="
    end

    test "does not require path_helper when passing event" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path_helper: nil
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "class") == ["pagination-previous"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-page") == ["1"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "raises if neither path helper nor event are passed" do
      assert_raise RuntimeError, fn ->
        render_component(&pagination/1,
          __changed__: nil,
          meta: build(:meta_on_second_page)
        )
      end
    end

    test "adds filter parameters to links" do
      html =
        render_pagination(
          meta:
            build(
              :meta_on_second_page,
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
          ~s(filters[0][field]=fur_length&) <>
            ~s(filters[0][op]=%3E%3D&) <>
            ~s(filters[0][value]=5&) <>
            ~s(filters[1][field]=curiosity&) <>
            ~s(filters[1][op]=in&) <>
            ~s(filters[1][value][]=a_lot&) <>
            ~s(filters[1][value][]=somewhat&) <>
            ~s(page_size=10)

        if page == 1,
          do: "/pets?" <> default,
          else: ~s(/pets?page=#{page}&) <> default
      end

      assert [previous] = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(previous, "class") == ["pagination-previous"]
      assert Floki.attribute(previous, "data-phx-link") == ["patch"]
      assert Floki.attribute(previous, "data-phx-link-state") == ["push"]
      assert Floki.attribute(previous, "href") == [expected_url.(1)]

      assert [one] = Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.attribute(one, "class") == ["pagination-link"]
      assert Floki.attribute(one, "data-phx-link") == ["patch"]
      assert Floki.attribute(one, "data-phx-link-state") == ["push"]
      assert Floki.attribute(one, "href") == [expected_url.(1)]

      assert [next] = Floki.find(html, "a:fl-contains('Next')")
      assert Floki.attribute(next, "class") == ["pagination-next"]
      assert Floki.attribute(next, "data-phx-link") == ["patch"]
      assert Floki.attribute(next, "data-phx-link-state") == ["push"]
      assert Floki.attribute(next, "href") == [expected_url.(3)]
    end

    test "does not render ellipsis if total pages <= max pages" do
      # max pages smaller than total pages
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          page_links: {:ellipsis, 50}
        )

      assert Floki.find(html, ".pagination-ellipsis") == []
      assert html |> Floki.find(".pagination-link") |> length() == 5

      # max pages equal to total pages
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          page_links: {:ellipsis, 5}
        )

      assert Floki.find(html, ".pagination-ellipsis") == []
      assert html |> Floki.find(".pagination-link") |> length() == 5
    end

    test "renders end ellipsis and last page link when on page 1" do
      # current page == 1
      html =
        render_pagination(
          meta: build(:meta_on_first_page, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 1
      assert html |> Floki.find(".pagination-link") |> length() == 6

      assert Floki.find(html, "a[aria-label='Go to page 20']")

      for i <- 1..5 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders start ellipsis and first page link when on last page" do
      # current page == last page
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 20, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 1
      assert html |> Floki.find(".pagination-link") |> length() == 6

      assert Floki.find(html, "a[aria-label='Go to page 1']")

      for i <- 16..20 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on even page with even number of max pages" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 12, total_pages: 20),
          opts: [page_links: {:ellipsis, 6}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 2
      assert html |> Floki.find(".pagination-link") |> length() == 8

      assert Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.find(html, "a[aria-label='Go to page 20']")

      for i <- 10..15 do
        assert Floki.find(html, ".a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on odd page with odd number of max pages" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 11, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 2
      assert html |> Floki.find(".pagination-link") |> length() == 7

      assert Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.find(html, "a[aria-label='Go to page 20']")

      for i <- 9..13 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on even page with odd number of max pages" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 10, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 2
      assert html |> Floki.find(".pagination-link") |> length() == 7

      assert Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.find(html, "a[aria-label='Go to page 20']")

      for i <- 8..12 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on odd page with even number of max pages" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 11, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 2
      assert html |> Floki.find(".pagination-link") |> length() == 7

      assert Floki.find(html, "a[aria-label='Go to page 1']")
      assert Floki.find(html, "a[aria-label='Go to page 20']")

      for i <- 9..13 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders end ellipsis when on page close to the beginning" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 2, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 1
      assert html |> Floki.find(".pagination-link") |> length() == 6

      assert Floki.find(html, "a[aria-label='Go to page 20']")

      for i <- 1..5 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders start ellipsis when on page close to the end" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 18, total_pages: 20),
          opts: [page_links: {:ellipsis, 5}]
        )

      assert html |> Floki.find(".pagination-ellipsis") |> length() == 1
      assert html |> Floki.find(".pagination-link") |> length() == 6

      assert Floki.find(html, "a[aria-label='Go to page 1']")

      for i <- 16..20 do
        assert Floki.find(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "allows to overwrite ellipsis attributes and content" do
      html =
        render_pagination(
          meta: build(:meta_on_first_page, current_page: 10, total_pages: 20),
          opts: [
            page_links: {:ellipsis, 5},
            ellipsis_attrs: [class: "dotdotdot", title: "dot"],
            ellipsis_content: "dot dot dot"
          ]
        )

      assert [el, _] = Floki.find(html, "span[class='dotdotdot']")
      assert Floki.text(el) == "dot dot dot"
    end

    test "always uses page/page_size" do
      html =
        render_pagination(
          meta:
            build(:meta_on_second_page,
              flop: %Flop{limit: 2, page: 2, page_size: nil, offset: 3}
            )
        )

      assert [a | _] = Floki.find(html, "a")
      assert [href] = Floki.attribute(a, "href")
      assert href =~ "page_size=2"
      refute href =~ "limit=2"
      refute href =~ "offset=3"
    end
  end

  describe "table/1" do
    test "allows to set table attributes" do
      # attribute from global config
      html = render_table(opts: [])
      assert [table] = Floki.find(html, "table")
      assert Floki.attribute(table, "class") == ["sortable-table"]

      html = render_table(opts: [table_attrs: [class: "funky-table"]])
      assert [table] = Floki.find(html, "table")
      assert Floki.attribute(table, "class") == ["funky-table"]
    end

    test "optionally adds a table container" do
      html = render_table(opts: [])
      assert Floki.find(html, ".table-container") == []

      html = render_table(opts: [container: true])
      assert [_] = Floki.find(html, ".table-container")
    end

    test "allows to set container attributes" do
      html =
        render_table(
          opts: [
            container_attrs: [class: "container", id: "a"],
            container: true
          ]
        )

      assert [container] = Floki.find(html, "div.container")
      assert Floki.attribute(container, "id") == ["a"]
    end

    test "allows to set tr and td classes" do
      html =
        render_table(
          opts: [
            thead_tr_attrs: [class: "mungo"],
            thead_th_attrs: [class: "bean"],
            tbody_tr_attrs: [class: "salt"],
            tbody_td_attrs: [class: "tolerance"]
          ]
        )

      assert [_] = Floki.find(html, "tr.mungo")
      assert [_, _, _, _] = Floki.find(html, "th.bean")
      assert [_] = Floki.find(html, "tr.salt")
      assert [_, _, _, _] = Floki.find(html, "td.tolerance")
    end

    test "doesn't render table if items list is empty" do
      assert [{"p", [], ["No results."]}] = render_table(items: [])
    end

    test "displays headers without sorting function" do
      html = render_table()
      assert [th] = Floki.find(html, "th:fl-contains('Age')")
      assert Floki.children(th, include_text: false) == []
    end

    test "displays headers with sorting function" do
      html = render_table()

      assert [a] = Floki.find(html, "th a:fl-contains('Name')")
      assert Floki.attribute(a, "data-phx-link") == ["patch"]
      assert Floki.attribute(a, "data-phx-link-state") == ["push"]

      assert Floki.attribute(a, "href") == [
               "/pets?order_directions[]=asc&order_by[]=name"
             ]
    end

    test "supports a function/args tuple as path_helper" do
      html = render_table(path_helper: {&route_helper/3, @route_helper_opts})

      assert [a] = Floki.find(html, "th a:fl-contains('Name')")

      assert Floki.attribute(a, "href") == [
               "/pets?order_directions[]=asc&order_by[]=name"
             ]
    end

    test "displays headers with safe HTML values" do
      html = render_table([], &test_table_with_html_header/1)
      assert [span] = Floki.find(html, "th a span")
      assert Floki.text(span) == "Hello"
    end

    test "adds aria-sort attribute to first ordered field" do
      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{
              order_by: [:email, :name],
              order_directions: [:asc, :desc]
            }
          }
        )

      assert [th_name, th_email, th_age, th_species] = Floki.find(html, "th")
      assert Floki.attribute(th_name, "aria-sort") == []
      assert Floki.attribute(th_email, "aria-sort") == ["ascending"]
      assert Floki.attribute(th_age, "aria-sort") == []
      assert Floki.attribute(th_species, "aria-sort") == []

      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{
              order_by: [:name, :email],
              order_directions: [:desc, :asc]
            }
          }
        )

      assert [th_name, th_email, th_age, th_species] = Floki.find(html, "th")
      assert Floki.attribute(th_name, "aria-sort") == ["descending"]
      assert Floki.attribute(th_email, "aria-sort") == []
      assert Floki.attribute(th_age, "aria-sort") == []
      assert Floki.attribute(th_species, "aria-sort") == []

      html =
        render_table(
          meta: %Flop.Meta{flop: %Flop{order_by: [], order_directions: []}}
        )

      assert [th_name, th_email, th_age, th_species] = Floki.find(html, "th")
      assert Floki.attribute(th_name, "aria-sort") == []
      assert Floki.attribute(th_email, "aria-sort") == []
      assert Floki.attribute(th_age, "aria-sort") == []
      assert Floki.attribute(th_species, "aria-sort") == []
    end

    test "renders links with click handler" do
      html = render_table(event: "sort", path_helper: nil)

      assert [a] = Floki.find(html, "th a:fl-contains('Name')")
      assert Floki.attribute(a, "href") == ["#"]
      assert Floki.attribute(a, "phx-click") == ["sort"]
      assert Floki.attribute(a, "phx-value-order") == ["name"]

      assert [a] = Floki.find(html, "th a:fl-contains('Email')")
      assert Floki.attribute(a, "href") == ["#"]
      assert Floki.attribute(a, "phx-click") == ["sort"]
      assert Floki.attribute(a, "phx-value-order") == ["email"]
    end

    test "adds phx-target to header links" do
      html = render_table(event: "sort", path_helper: nil, target: "here")

      assert [a] = Floki.find(html, "th a:fl-contains('Name')")
      assert Floki.attribute(a, "href") == ["#"]
      assert Floki.attribute(a, "phx-click") == ["sort"]
      assert Floki.attribute(a, "phx-target") == ["here"]
      assert Floki.attribute(a, "phx-value-order") == ["name"]
    end

    test "checks for sortability if for option is set" do
      # without :for option
      html = render_table()

      assert [_] = Floki.find(html, "a:fl-contains('Name')")
      assert [_] = Floki.find(html, "a:fl-contains('Species')")

      # with :for assign
      html = render_table(for: Flop.Phoenix.Pet)

      assert [_] = Floki.find(html, "a:fl-contains('Name')")
      assert [] = Floki.find(html, "a:fl-contains('Species')")
    end

    test "hides default order and limit" do
      html =
        render_table(
          for: Pet,
          meta:
            build(
              :meta_on_second_page,
              flop: %Flop{
                page_size: 20,
                order_by: [:name],
                order_directions: [:desc]
              }
            )
        )

      assert [link] = Floki.find(html, "a:fl-contains('Name')")
      assert [href] = Floki.attribute(link, "href")

      refute href =~ "page_size="
      refute href =~ "order_by[]="
      refute href =~ "order_directions[]="
    end

    test "renders order direction symbol" do
      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:name], order_directions: [:asc]}
          }
        )

      assert Floki.find(
               html,
               "a:fl-contains('Email') + span.order-direction"
             ) == []

      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:email], order_directions: [:asc]}
          }
        )

      assert [span] =
               Floki.find(
                 html,
                 "th a:fl-contains('Email') + span.order-direction"
               )

      assert Floki.text(span) == "▴"

      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:email], order_directions: [:desc]}
          }
        )

      assert [span] =
               Floki.find(
                 html,
                 "th a:fl-contains('Email') + span.order-direction"
               )

      assert Floki.text(span) == "▾"
    end

    test "allows to set symbol class" do
      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:name], order_directions: [:asc]}
          },
          opts: [symbol_attrs: [class: "other-class"]]
        )

      assert [_] = Floki.find(html, "span.other-class")
    end

    test "allows to override default symbols" do
      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:name], order_directions: [:asc]}
          },
          opts: [symbol_asc: "asc"]
        )

      assert [span] = Floki.find(html, "span.order-direction")
      assert Floki.text(span) == "asc"

      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:name], order_directions: [:desc]}
          },
          opts: [symbol_desc: "desc"]
        )

      assert [span] = Floki.find(html, "span.order-direction")
      assert Floki.text(span) == "desc"
    end

    test "renders notice if item list is empty" do
      assert [{"p", [], ["No results."]}] = render_table(items: [])
    end

    test "allows to set no_results_content" do
      assert render_table(
               items: [],
               opts: [no_results_content: content_tag(:div, do: "Nothing!")]
             ) == [{"div", [], ["Nothing!"]}]
    end

    test "renders table foot" do
      html = render_table([], &test_table_with_foot/1)

      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"thead", _, _},
                  {"tbody", _, _},
                  {"tfoot", [], [{"tr", [], [{"td", [], ["snap"]}]}]}
                ]}
             ] = html
    end

    test "does not render table foot if option is not set" do
      html = render_table()

      assert [
               {"table", [{"class", "sortable-table"}],
                [{"thead", _, _}, {"tbody", _, _}]}
             ] = html
    end

    test "does not require path_helper when passing event" do
      html = render_table(event: "sort-table", path_helper: nil)

      assert [link] = Floki.find(html, "a:fl-contains('Name')")
      assert Floki.attribute(link, "phx-click") == ["sort-table"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "raises if no cols are passed" do
      assert_raise RuntimeError,
                   ~r/^You need to add at least one `<:col>`/,
                   fn ->
                     render_component(&table/1,
                       __changed__: nil,
                       event: "sort",
                       items: [],
                       meta: %Flop.Meta{flop: %Flop{}}
                     )
                   end
    end

    test "raises if no items are passed" do
      assert_raise RuntimeError,
                   ~r/^You need to set the `items` assign/,
                   fn ->
                     render_component(&table/1,
                       __changed__: nil,
                       col: fn _ -> nil end,
                       event: "sort",
                       meta: %Flop.Meta{flop: %Flop{}}
                     )
                   end
    end

    test "raises if no meta is passed" do
      assert_raise RuntimeError,
                   ~r/^You need to set the `meta` assign/,
                   fn ->
                     render_component(&table/1,
                       __changed__: nil,
                       col: fn _ -> nil end,
                       event: "sort",
                       items: []
                     )
                   end
    end

    test "raises if neither path helper nor event are passed" do
      assert_raise RuntimeError,
                   ~r/^Flop.Phoenix.table requires either the `path_helper`/,
                   fn ->
                     render_component(&table/1,
                       __changed__: nil,
                       col: fn _ -> nil end,
                       items: [%{name: "George"}],
                       meta: %Flop.Meta{flop: %Flop{}}
                     )
                   end
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
