defmodule Flop.PhoenixTest do
  use ExUnit.Case
  use Phoenix.Component
  use Phoenix.HTML

  import Flop.Phoenix
  import Flop.Phoenix.Factory
  import Flop.Phoenix.ViewHelpers
  import Phoenix.LiveViewTest

  alias Flop.Filter
  alias Flop.Phoenix.Pet
  alias Phoenix.LiveView.JS
  alias Plug.Conn.Query

  doctest Flop.Phoenix, import: true

  @route_helper_opts [%{}, :pets]

  defp render_pagination(assigns) do
    assigns = Keyword.put(assigns, :__changed__, nil)

    assigns =
      if assigns[:path] || assigns[:path_helper] do
        assigns
      else
        Keyword.put_new(
          assigns,
          :path,
          {__MODULE__, :route_helper, @route_helper_opts}
        )
      end

    (&pagination/1)
    |> render_component(assigns)
    |> Floki.parse_fragment!()
  end

  defp render_cursor_pagination(assigns) do
    assigns = Keyword.put(assigns, :__changed__, nil)

    assigns =
      if assigns[:path] || assigns[:path_helper] do
        assigns
      else
        Keyword.put_new(
          assigns,
          :path,
          {__MODULE__, :route_helper, @route_helper_opts}
        )
      end

    (&cursor_pagination/1)
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
      |> assign_new(:caption, fn -> nil end)
      |> assign_new(:for, fn -> nil end)
      |> assign_new(:event, fn -> nil end)
      |> assign_new(:items, fn ->
        [%{name: "George", email: "george@george.pet", age: 8, species: "dog"}]
      end)
      |> assign_new(:meta, fn -> %Flop.Meta{flop: %Flop{}} end)
      |> assign_new(:opts, fn -> [] end)
      |> assign_new(:target, fn -> nil end)
      |> assign_new(:hide_age, fn -> false end)
      |> assign_new(:show_age, fn -> true end)

    assigns =
      if assigns[:path] || assigns[:path_helper] do
        assigns
        |> assign_new(:path, fn -> nil end)
        |> assign_new(:path_helper, fn -> nil end)
      else
        assigns
        |> assign_new(:path, fn ->
          {__MODULE__, :route_helper, @route_helper_opts}
        end)
        |> assign_new(:path_helper, fn -> nil end)
      end

    ~H"""
    <Flop.Phoenix.table
      caption={@caption}
      event={@event}
      items={@items}
      meta={@meta}
      opts={@opts}
      path={@path}
      path_helper={@path_helper}
      target={@target}
    >
      <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
      <:col :let={pet} label="Email" field={:email}><%= pet.email %></:col>
      <:col :let={pet} label="Age" hide={@hide_age} show={@show_age}>
        <%= pet.age %>
      </:col>
      <:col :let={pet} label="Species" field={:species}><%= pet.species %></:col>
      <:col>column without label</:col>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_widths(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George", age: 8}]}
      meta={%Flop.Meta{flop: %Flop{}}}
    >
      <:col :let={pet} label="Name" field={:name} col_style="width: 60%;">
        <%= pet.name %>
      </:col>
      <:col :let={pet} label="Age" field={:age} col_style="width: 40%;">
        <%= pet.age %>
      </:col>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_column_attrs(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George", age: 8}, %{name: "Mary", age: 10}]}
      meta={%Flop.Meta{flop: %Flop{}}}
    >
      <:col :let={pet} label="Name" field={:name} attrs={[class: "name-column"]}>
        <%= pet.name %>
      </:col>
      <:col :let={pet} label="Age" field={:age} attrs={[class: "age-column"]}>
        <%= pet.age %>
      </:col>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_action(assigns) do
    assigns =
      assigns
      |> assign_new(:hide_action, fn -> false end)
      |> assign_new(:show_action, fn -> true end)
      |> assign_new(:opts, fn -> [] end)

    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George", age: 8}, %{name: "Mary", age: 10}]}
      meta={%Flop.Meta{flop: %Flop{}}}
      opts={@opts}
    >
      <:col :let={pet} label="Name" field={:name} attrs={[class: "name-column"]}>
        <%= pet.name %>
      </:col>
      <:col :let={pet} label="Age" field={:age} attrs={[class: "age-column"]}>
        <%= pet.age %>
      </:col>
      <:action :let={pet} hide={@hide_action} show={@show_action} label="Buttons">
        <.link navigate={"/show/pet/#{pet.name}"}>Show Pet</.link>
      </:action>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_action_and_with_widths(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George", id: 1}]}
      meta={%Flop.Meta{flop: %Flop{}}}
    >
      <:col :let={pet} label="Name" field={:name} col_style="width: 60%;">
        <%= pet.name %>
      </:col>
      <:action :let={pet} col_style="width: 40%;">
        <.link navigate={"/show/pet/#{pet.name}"}>
          Show Pet
        </.link>
      </:action>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_row_click_and_action(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George", id: 1}]}
      meta={%Flop.Meta{flop: %Flop{}}}
      row_click={&JS.navigate("/show/#{&1.id}")}
    >
      <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
      <:action :let={pet}>
        <.link navigate={"/show/pet/#{pet.name}"}>Show Pet</.link>
      </:action>
    </Flop.Phoenix.table>
    """
  end

  defp test_table_with_action_header(assigns) do
    ~H"""
    <Flop.Phoenix.table
      event="sort"
      items={[%{name: "George"}]}
      meta={%Flop.Meta{flop: %Flop{}}}
    >
      <:col :let={pet}>
        <%= pet.name %>
      </:col>
      <:action :let={pet} label={{:safe, "<span>Hello</span>"}}>
        <%= pet.name %>
      </:action>
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
      <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
      <:foot>
        <tr>
          <td>snap</td>
        </tr>
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
      <:col :let={pet} label={{:safe, "<span>Hello</span>"}} field={:name}>
        <%= pet.name %>
      </:col>
    </Flop.Phoenix.table>
    """
  end

  def route_helper(%{}, action, query) do
    URI.to_string(%URI{path: "/#{action}", query: Query.encode(query)})
  end

  def path_func(params) do
    {page, params} = Keyword.pop(params, :page)
    query = Query.encode(params)
    if page, do: "/pets/page/#{page}?#{query}", else: "/pets?#{query}"
  end

  describe "pagination/1" do
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

    test "supports a function/args tuple as path" do
      html =
        render_pagination(
          path: {&route_helper/3, @route_helper_opts},
          meta: build(:meta_on_second_page)
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

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

    test "supports a function as path" do
      html =
        render_pagination(
          path: &path_func/1,
          meta: build(:meta_on_first_page)
        )

      link = Floki.find(html, "a:fl-contains('Next')")
      assert Floki.attribute(link, "href") == ["/pets/page/2?page_size=10"]
    end

    test "supports a URI string as path" do
      html = render_pagination(path: "/pets", meta: build(:meta_on_second_page))
      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "href") == ["/pets?page_size=10"]
    end

    test "renders previous link when using click event handling" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path: nil
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
          path: nil,
          target: "here"
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "phx-target") == ["here"]
    end

    test "merges query parameters into existing parameters" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          path:
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

    test "merges query parameters into existing path query parameters" do
      html =
        render_pagination(
          meta: build(:meta_on_second_page),
          path: "/pets?category=dinosaurs",
          opts: []
        )

      assert [previous] = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(previous, "class") == ["pagination-previous"]
      assert Floki.attribute(previous, "data-phx-link") == ["patch"]
      assert Floki.attribute(previous, "data-phx-link-state") == ["push"]

      assert Floki.attribute(previous, "href") == [
               "/pets?page_size=10&category=dinosaurs"
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

      assert Floki.attribute(previous_link, "class") == [
               "pagination-previous disabled"
             ]
    end

    test "disables previous link if on first page when using click handlers" do
      html =
        render_pagination(
          event: "e",
          meta: build(:meta_on_first_page),
          path: nil
        )

      previous_link = Floki.find(html, "span:fl-contains('Previous')")

      assert Floki.attribute(previous_link, "class") == [
               "pagination-previous disabled"
             ]
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

      assert Floki.attribute(previous_link, "class") == ["prev disabled"]
      assert Floki.attribute(previous_link, "title") == ["no"]
      assert String.trim(Floki.text(previous_link)) == "Prev"
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
        [event: "paginate", meta: build(:meta_on_second_page), path: nil]
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
          path: nil,
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

      assert Floki.attribute(next, "class") == ["pagination-next disabled"]
      assert Floki.attribute(next, "href") == []
    end

    test "renders next link on last page when using click event handling" do
      next =
        [event: "paginate", meta: build(:meta_on_last_page), path: nil]
        |> render_pagination()
        |> Floki.find("span:fl-contains('Next')")

      assert Floki.attribute(next, "class") == ["pagination-next disabled"]
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

      assert Floki.attribute(next_link, "class") == ["next disabled"]
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
      assert String.trim(Floki.text(link)) == "1"

      assert [link] = Floki.find(html, "a[aria-label='Go to page 2']")
      assert Floki.attribute(link, "class") == ["pagination-link is-current"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=2&page_size=10"]
      assert String.trim(Floki.text(link)) == "2"

      assert [link] = Floki.find(html, "a[aria-label='Go to page 3']")
      assert Floki.attribute(link, "class") == ["pagination-link"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=3&page_size=10"]
      assert String.trim(Floki.text(link)) == "3"
    end

    test "renders page links when using click event handling" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path: nil
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
          path: nil,
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
      assert String.trim(Floki.text(link)) == "1"

      assert [link] = Floki.find(html, "a[aria-label='Go to page 2']")
      assert Floki.attribute(link, "beep") == ["boop"]
      assert Floki.attribute(link, "class") == ["link is-active"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=2&page_size=10"]
      assert String.trim(Floki.text(link)) == "2"
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
      assert String.trim(Floki.text(link)) == "1"

      assert [link] = Floki.find(html, "a[aria-label='On to page 2']")
      assert Floki.attribute(link, "class") == ["pagination-link is-current"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?page=2&page_size=10"]
      assert String.trim(Floki.text(link)) == "2"
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
          meta:
            build(
              :meta_on_second_page,
              flop: %Flop{
                page_size: 20,
                order_by: [:name],
                order_directions: [:asc]
              },
              schema: Pet
            )
        )

      assert [prev] = Floki.find(html, "a:fl-contains('Previous')")
      assert [href] = Floki.attribute(prev, "href")

      refute href =~ "page_size="
      refute href =~ "order_by[]="
      refute href =~ "order_directions[]="
    end

    test "does not require path when passing event" do
      html =
        render_pagination(
          event: "paginate",
          meta: build(:meta_on_second_page),
          path: nil
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "class") == ["pagination-previous"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-page") == ["1"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "raises if neither path nor event are passed" do
      assert_raise ArgumentError,
                   ~r/^the :path or :event option is required/,
                   fn ->
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

    @tag capture_log: true
    test "does not render anything if meta has errors" do
      {:error, meta} = Flop.validate(%{page: 0})
      assert render_pagination(meta: meta) == []
    end
  end

  describe "cursor_pagination/1" do
    test "renders pagination wrapper" do
      html = render_cursor_pagination(meta: build(:meta_with_cursors))
      wrapper = Floki.find(html, "nav")

      assert Floki.attribute(wrapper, "aria-label") == ["pagination"]
      assert Floki.attribute(wrapper, "class") == ["pagination"]
      assert Floki.attribute(wrapper, "role") == ["navigation"]
    end

    test "allows to overwrite wrapper class" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors),
          opts: [wrapper_attrs: [class: "boo"]]
        )

      wrapper = Floki.find(html, "nav")

      assert Floki.attribute(wrapper, "aria-label") == ["pagination"]
      assert Floki.attribute(wrapper, "class") == ["boo"]
      assert Floki.attribute(wrapper, "role") == ["navigation"]
    end

    test "allows to add attributes to wrapper" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors),
          opts: [wrapper_attrs: [title: "paginate"]]
        )

      wrapper = Floki.find(html, "nav")

      assert Floki.attribute(wrapper, "aria-label") == ["pagination"]
      assert Floki.attribute(wrapper, "class") == ["pagination"]
      assert Floki.attribute(wrapper, "role") == ["navigation"]
      assert Floki.attribute(wrapper, "title") == ["paginate"]
    end

    test "renders previous link" do
      html = render_cursor_pagination(meta: build(:meta_with_cursors))
      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "class") == ["pagination-previous"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?last=10&before=B"]
    end

    test "supports a function/args tuple as path" do
      html =
        render_cursor_pagination(
          path: {&route_helper/3, @route_helper_opts},
          meta: build(:meta_with_cursors)
        )

      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "href") == ["/pets?last=10&before=B"]
    end

    test "supports a function/args tuple as path_helper" do
      html =
        render_cursor_pagination(
          path_helper: {&route_helper/3, @route_helper_opts},
          meta: build(:meta_with_cursors)
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "href") == [
               "/pets?last=10&before=B"
             ]
    end

    test "supports a function as path" do
      html =
        render_cursor_pagination(
          path: &path_func/1,
          meta: build(:meta_with_cursors)
        )

      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "href") == ["/pets?last=10&before=B"]
    end

    test "supports a URI string as path" do
      html =
        render_cursor_pagination(
          path: "/pets",
          meta: build(:meta_with_cursors)
        )

      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "href") == ["/pets?before=B&last=10"]
    end

    test "renders previous link when using click event handling" do
      html =
        render_cursor_pagination(
          event: "paginate",
          meta: build(:meta_with_cursors),
          path: nil
        )

      link = Floki.find(html, "a:fl-contains('Previous')")

      assert Floki.attribute(link, "class") == ["pagination-previous"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-to") == ["previous"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "adds phx-target to previous link" do
      html =
        render_cursor_pagination(
          event: "paginate",
          meta: build(:meta_with_cursors),
          path: nil,
          target: "here"
        )

      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "phx-target") == ["here"]
    end

    test "switches next and previous link" do
      # default
      html = render_cursor_pagination(meta: build(:meta_with_cursors))

      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "href") == ["/pets?last=10&before=B"]
      link = Floki.find(html, "a:fl-contains('Next')")
      assert Floki.attribute(link, "href") == ["/pets?first=10&after=C"]

      # reverse
      html =
        render_cursor_pagination(meta: build(:meta_with_cursors), reverse: true)

      link = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(link, "href") == ["/pets?first=10&after=C"]

      link = Floki.find(html, "a:fl-contains('Next')")
      assert Floki.attribute(link, "href") == ["/pets?last=10&before=B"]
    end

    test "merges query parameters into existing parameters" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors),
          path:
            {&route_helper/3, @route_helper_opts ++ [[category: "dinosaurs"]]},
          opts: []
        )

      assert [previous] = Floki.find(html, "a:fl-contains('Previous')")
      assert Floki.attribute(previous, "class") == ["pagination-previous"]
      assert Floki.attribute(previous, "data-phx-link") == ["patch"]
      assert Floki.attribute(previous, "data-phx-link-state") == ["push"]

      assert Floki.attribute(previous, "href") == [
               "/pets?category=dinosaurs&last=10&before=B"
             ]
    end

    test "allows to overwrite previous link attributes and content" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors),
          opts: [
            previous_link_attrs: [class: "prev", title: "p-p-previous"],
            previous_link_content: tag(:i, class: "fas fa-chevron-left")
          ]
        )

      assert [link] = Floki.find(html, "a[title='p-p-previous']")
      assert Floki.attribute(link, "class") == ["prev"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?last=10&before=B"]

      assert link |> Floki.children() |> Floki.raw_html() ==
               "<i class=\"fas fa-chevron-left\"></i>"
    end

    test "disables previous link if on first page" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors, has_previous_page?: false)
        )

      previous_link = Floki.find(html, "span:fl-contains('Previous')")

      assert Floki.attribute(previous_link, "class") == [
               "pagination-previous disabled"
             ]
    end

    test "disables previous link if on first page when using click handlers" do
      html =
        render_cursor_pagination(
          event: "e",
          meta: build(:meta_with_cursors, has_previous_page?: false),
          path: nil
        )

      previous_link = Floki.find(html, "span:fl-contains('Previous')")

      assert Floki.attribute(previous_link, "class") == [
               "pagination-previous disabled"
             ]
    end

    test "allows to overwrite previous link class and content if disabled" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors, has_previous_page?: false),
          opts: [
            previous_link_attrs: [class: "prev", title: "no"],
            previous_link_content: "Prev"
          ]
        )

      previous_link = Floki.find(html, "span:fl-contains('Prev')")

      assert Floki.attribute(previous_link, "class") == ["prev disabled"]
      assert Floki.attribute(previous_link, "title") == ["no"]
      assert String.trim(Floki.text(previous_link)) == "Prev"
    end

    test "renders next link" do
      link =
        [meta: build(:meta_with_cursors)]
        |> render_cursor_pagination()
        |> Floki.find("a:fl-contains('Next')")

      assert Floki.attribute(link, "class") == ["pagination-next"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?first=10&after=C"]
    end

    test "renders next link when using click event handling" do
      link =
        [event: "paginate", meta: build(:meta_with_cursors), path: nil]
        |> render_cursor_pagination()
        |> Floki.find("a:fl-contains('Next')")

      assert Floki.attribute(link, "class") == ["pagination-next"]
      assert Floki.attribute(link, "phx-click") == ["paginate"]
      assert Floki.attribute(link, "phx-value-to") == ["next"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "adds phx-target to next link" do
      link =
        [
          event: "paginate",
          meta: build(:meta_with_cursors),
          path: nil,
          target: "here"
        ]
        |> render_cursor_pagination()
        |> Floki.find("a:fl-contains('Next')")

      assert Floki.attribute(link, "phx-target") == ["here"]
    end

    test "allows to overwrite next link attributes and content" do
      html =
        render_cursor_pagination(
          meta: build(:meta_with_cursors),
          opts: [
            next_link_attrs: [class: "next", title: "n-n-next"],
            next_link_content: tag(:i, class: "fas fa-chevron-right")
          ]
        )

      assert [link] = Floki.find(html, "a[title='n-n-next']")
      assert Floki.attribute(link, "class") == ["next"]
      assert Floki.attribute(link, "data-phx-link") == ["patch"]
      assert Floki.attribute(link, "data-phx-link-state") == ["push"]
      assert Floki.attribute(link, "href") == ["/pets?first=10&after=C"]

      assert link |> Floki.children() |> Floki.raw_html() ==
               "<i class=\"fas fa-chevron-right\"></i>"
    end

    test "disables next link if on last page" do
      next =
        [meta: build(:meta_with_cursors, has_next_page?: false)]
        |> render_cursor_pagination()
        |> Floki.find("span:fl-contains('Next')")

      assert Floki.attribute(next, "class") == ["pagination-next disabled"]
      assert Floki.attribute(next, "href") == []
    end

    test "renders next link on last page when using click event handling" do
      next =
        [
          event: "paginate",
          meta: build(:meta_with_cursors, has_next_page?: false),
          path: nil
        ]
        |> render_cursor_pagination()
        |> Floki.find("span:fl-contains('Next')")

      assert Floki.attribute(next, "class") == ["pagination-next disabled"]
      assert Floki.attribute(next, "href") == []
    end

    test "allows to overwrite next link attributes and content when disabled" do
      next_link =
        [
          meta: build(:meta_with_cursors, has_next_page?: false),
          opts: [
            next_link_attrs: [class: "next", title: "no"],
            next_link_content: "N-n-next"
          ]
        ]
        |> render_cursor_pagination()
        |> Floki.find("span:fl-contains('N-n-next')")

      assert Floki.attribute(next_link, "class") == ["next disabled"]
      assert Floki.attribute(next_link, "title") == ["no"]
    end

    test "raises if neither path nor event are passed" do
      assert_raise ArgumentError,
                   ~r/^the :path or :event option is required/,
                   fn ->
                     render_component(&cursor_pagination/1,
                       __changed__: nil,
                       meta: build(:meta_with_cursors)
                     )
                   end
    end

    @tag capture_log: true
    test "does not render anything if meta has errors" do
      {:error, meta} = Flop.validate(%{first: 1, last: 1})
      assert render_cursor_pagination(meta: meta) == []
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

    test "allows to set tbody attributes" do
      html =
        render_table(
          opts: [
            tbody_attrs: [class: "mango_body"],
            container: true
          ]
        )

      assert [_] = Floki.find(html, "tbody.mango_body")
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
      assert [_, _, _, _, _] = Floki.find(html, "th.bean")
      assert [_] = Floki.find(html, "tr.salt")
      assert [_, _, _, _, _] = Floki.find(html, "td.tolerance")
    end

    test "allows to set td class on action" do
      html =
        render_table(
          [
            opts: [
              tbody_td_attrs: [class: "tolerance"]
            ]
          ],
          &test_table_with_action/1
        )

      assert [_, _, _, _, _, _] = Floki.find(html, "td.tolerance")
    end

    test "adds additional attributes to td within action" do
      html = render_table([opts: []], &test_table_with_action/1)
      assert [_, _] = Floki.find(html, "td.name-column")
      assert [_, _] = Floki.find(html, "td.age-column")
    end

    test "adds additional attributes to td" do
      html = render_table([], &test_table_with_column_attrs/1)
      assert [_, _] = Floki.find(html, "td.name-column")
      assert [_, _] = Floki.find(html, "td.age-column")
    end

    test "doesn't render table if items list is empty" do
      assert [{"p", [], ["No results."]}] = render_table(items: [])
    end

    test "displays headers for action col" do
      html = render_table([], &test_table_with_action/1)
      assert [th] = Floki.find(html, "th:fl-contains('Buttons')")
      assert Floki.children(th, include_text: false) == []
    end

    test "displays headers without sorting function" do
      html = render_table()
      assert [th] = Floki.find(html, "th:fl-contains('Age')")
      assert Floki.children(th, include_text: false) == []
    end

    test "conditionally hides a column" do
      html = render_table()
      assert [_] = Floki.find(html, "th:fl-contains('Age')")
      assert [_] = Floki.find(html, "td:fl-contains('8')")

      html = render_table(hide_age: false, show_age: true)
      assert [_] = Floki.find(html, "th:fl-contains('Age')")
      assert [_] = Floki.find(html, "td:fl-contains('8')")

      html = render_table(hide_age: true, show_age: true)
      assert [] = Floki.find(html, "th:fl-contains('Age')")
      assert [] = Floki.find(html, "td:fl-contains('8')")

      html = render_table(hide_age: false, show_age: false)
      assert [] = Floki.find(html, "th:fl-contains('Age')")
      assert [] = Floki.find(html, "td:fl-contains('8')")

      html = render_table(hide_age: true, show_age: false)
      assert [] = Floki.find(html, "th:fl-contains('Age')")
      assert [] = Floki.find(html, "td:fl-contains('8')")
    end

    test "conditionally hides an action column" do
      html = render_table([], &test_table_with_action/1)

      assert [_] = Floki.find(html, "th:fl-contains('Buttons')")
      assert [_, _] = Floki.find(html, "a:fl-contains('Show Pet')")

      html =
        render_table(
          [hide_action: false, show_action: true],
          &test_table_with_action/1
        )

      assert [_] = Floki.find(html, "th:fl-contains('Buttons')")
      assert [_, _] = Floki.find(html, "a:fl-contains('Show Pet')")

      html =
        render_table(
          [hide_action: true, show_action: true],
          &test_table_with_action/1
        )

      assert [] = Floki.find(html, "th:fl-contains('Buttons')")
      assert [] = Floki.find(html, "td:fl-contains('Show Pet')")

      html =
        render_table(
          [hide_action: true, show_action: false],
          &test_table_with_action/1
        )

      assert [] = Floki.find(html, "th:fl-contains('Buttons')")
      assert [] = Floki.find(html, "td:fl-contains('Show Pet')")

      html =
        render_table(
          [hide_action: false, show_action: false],
          &test_table_with_action/1
        )

      assert [] = Floki.find(html, "th:fl-contains('Buttons')")
      assert [] = Floki.find(html, "td:fl-contains('Show Pet')")
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

    test "supports a function/args tuple as path" do
      html = render_table(path: {&route_helper/3, @route_helper_opts})
      assert [a] = Floki.find(html, "th a:fl-contains('Name')")

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

    test "supports a function/ as path" do
      html = render_table(path: &path_func/1)
      assert [a] = Floki.find(html, "th a:fl-contains('Name')")

      assert Floki.attribute(a, "href") == [
               "/pets?order_directions[]=asc&order_by[]=name"
             ]
    end

    test "supports a URI string as path" do
      html = render_table(path: "/pets")
      assert [a] = Floki.find(html, "th a:fl-contains('Name')")

      assert Floki.attribute(a, "href") == [
               "/pets?order_by[]=name&order_directions[]=asc"
             ]
    end

    test "displays headers with safe HTML values in action col" do
      html = render_table([], &test_table_with_action_header/1)
      assert [span] = Floki.find(html, "th span")
      assert Floki.text(span) == "Hello"
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

      assert [th_name, th_email, th_age, th_species, _] = Floki.find(html, "th")
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

      assert [th_name, th_email, th_age, th_species, _] = Floki.find(html, "th")
      assert Floki.attribute(th_name, "aria-sort") == ["descending"]
      assert Floki.attribute(th_email, "aria-sort") == []
      assert Floki.attribute(th_age, "aria-sort") == []
      assert Floki.attribute(th_species, "aria-sort") == []

      html =
        render_table(
          meta: %Flop.Meta{flop: %Flop{order_by: [], order_directions: []}}
        )

      assert [th_name, th_email, th_age, th_species, _] = Floki.find(html, "th")
      assert Floki.attribute(th_name, "aria-sort") == []
      assert Floki.attribute(th_email, "aria-sort") == []
      assert Floki.attribute(th_age, "aria-sort") == []
      assert Floki.attribute(th_species, "aria-sort") == []
    end

    test "renders links with click handler" do
      html = render_table(event: "sort", path: nil, path_helper: nil)

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
      html =
        render_table(event: "sort", path: nil, path_helper: nil, target: "here")

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
      html = render_table(meta: %Flop.Meta{flop: %Flop{}, schema: Pet})

      assert [_] = Floki.find(html, "a:fl-contains('Name')")
      assert [] = Floki.find(html, "a:fl-contains('Species')")
    end

    test "hides default order and limit" do
      html =
        render_table(
          meta:
            build(
              :meta_on_second_page,
              flop: %Flop{
                page_size: 20,
                order_by: [:name],
                order_directions: [:desc]
              },
              schema: Pet
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

    test "allows to set indicator for unsorted column" do
      html =
        render_table(
          meta: %Flop.Meta{
            flop: %Flop{order_by: [:name], order_directions: [:asc]}
          },
          opts: [symbol_unsorted: "random"]
        )

      assert [span] =
               Floki.find(
                 html,
                 "th a:fl-contains('Email') + span.order-direction"
               )

      assert Floki.text(span) == "random"
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

    test "renders row_click" do
      html = render_table([], &test_table_with_row_click_and_action/1)

      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"thead", _, _},
                  {"tbody", _, rows}
                ]}
             ] = html

      # two columns in total, second one is for action
      assert [_, _] = Floki.find(rows, "td")

      # only one column should have phx-click attribute
      assert [_] = Floki.find(rows, "td[phx-click]")
    end

    test "does not render row_click if not set" do
      html = render_table([])

      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"thead", _, _},
                  {"tbody", _, rows}
                ]}
             ] = html

      assert [] = Floki.find(rows, "td[phx-click]")
    end

    test "renders table action" do
      html = render_table([opts: []], &test_table_with_action/1)

      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"thead", _, _},
                  {"tbody", _, rows}
                ]}
             ] = html

      assert [_] = Floki.find(rows, "a[href='/show/pet/Mary']")
      assert [_] = Floki.find(rows, "a[href='/show/pet/George']")
    end

    test "does not render action column if option is not set" do
      html = render_table([])

      assert [
               {"table", [{"class", "sortable-table"}],
                [{"thead", _, _}, {"tbody", _, rows}]}
             ] = html

      assert [] = Floki.find(rows, "a")

      # test table has five column
      assert [_, _, _, _, _] = Floki.find(rows, "td")
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

    test "renders colgroup" do
      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"colgroup", _,
                   [
                     {"col", [{"style", "width: 60%;"}], _},
                     {"col", [{"style", "width: 40%;"}], _}
                   ]},
                  {"thead", _, _},
                  {"tbody", _, _}
                ]}
             ] = render_table([], &test_table_with_widths/1)
    end

    test "does not render a colgroup if no style attribute is set" do
      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"thead", _, _},
                  {"tbody", _, _}
                ]}
             ] = render_table([], &test_table/1)
    end

    test "renders colgroup on action col" do
      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"colgroup", _,
                   [
                     {"col", [{"style", "width: 60%;"}], _},
                     {"col", [{"style", "width: 40%;"}], _}
                   ]},
                  {"thead", _, _},
                  {"tbody", _, _}
                ]}
             ] = render_table([], &test_table_with_action_and_with_widths/1)
    end

    test "does not render colgroup on action col if no style attribute is set" do
      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"thead", _, _},
                  {"tbody", _, _}
                ]}
             ] = render_table([], &test_table_with_action/1)
    end

    test "renders caption" do
      assert [
               {"table", [{"class", "sortable-table"}],
                [
                  {"caption", [], ["some caption"]},
                  {"thead", _, _},
                  {"tbody", _, _}
                ]}
             ] = render_table(caption: "some caption")
    end

    test "does not render table foot if option is not set" do
      html = render_table()

      assert [
               {"table", [{"class", "sortable-table"}],
                [{"thead", _, _}, {"tbody", _, _}]}
             ] = html
    end

    test "does not require path_helper when passing event" do
      html = render_table(event: "sort-table", path: nil, path_helper: nil)

      assert [link] = Floki.find(html, "a:fl-contains('Name')")
      assert Floki.attribute(link, "phx-click") == ["sort-table"]
      assert Floki.attribute(link, "href") == ["#"]
    end

    test "raises if neither path nor event are passed" do
      assert_raise ArgumentError,
                   ~r/^the :path or :event option is required/,
                   fn ->
                     render_component(&table/1,
                       __changed__: nil,
                       col: fn _ -> nil end,
                       items: [%{name: "George"}],
                       meta: %Flop.Meta{flop: %Flop{}}
                     )
                   end
    end

    @tag capture_log: true
    test "does not crash if meta has errors" do
      {:error, meta} = Flop.validate(%{page: 0})
      render_table(meta: meta)
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

  describe "hidden_inputs_for_filter/1" do
    test "generates hidden fields from the given form" do
      form = %{form_for(:form, "/") | hidden: [id: 1]}
      assigns = %{form: form}
      html = parse_heex(~H"<.hidden_inputs_for_filter form={@form} />")

      assert [input] = Floki.find(html, "input")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "id") == ["form_id"]
      assert Floki.attribute(input, "name") == ["form[id]"]
      assert Floki.attribute(input, "value") == ["1"]
    end

    test "generates hidden fields for lists from the given form" do
      form = %{form_for(:a, "/") | hidden: [field: ["a", "b", "c"]]}
      assigns = %{form: form}
      html = parse_heex(~H"<.hidden_inputs_for_filter form={@form} />")

      assert [input_1, input_2, input_3] = Floki.find(html, "input")

      assert Floki.attribute(input_1, "type") == ["hidden"]
      assert Floki.attribute(input_1, "id") == ["a_field_0"]
      assert Floki.attribute(input_1, "name") == ["a[field][]"]
      assert Floki.attribute(input_1, "value") == ["a"]

      assert Floki.attribute(input_2, "type") == ["hidden"]
      assert Floki.attribute(input_2, "id") == ["a_field_1"]
      assert Floki.attribute(input_2, "name") == ["a[field][]"]
      assert Floki.attribute(input_2, "value") == ["b"]

      assert Floki.attribute(input_3, "type") == ["hidden"]
      assert Floki.attribute(input_3, "id") == ["a_field_2"]
      assert Floki.attribute(input_3, "name") == ["a[field][]"]
      assert Floki.attribute(input_3, "value") == ["c"]
    end
  end

  describe "filter_fields/1" do
    setup do
      meta = build(:meta_on_first_page)

      fields = [
        {:email, label: "E-mail"},
        {:phone, op: :ilike, type: "tel", class: "phone-input"},
        :field_without_opts
      ]

      %{fields: fields, meta: meta}
    end

    test "renders the hidden inputs", %{fields: fields, meta: meta} do
      html = render_form(%{fields: fields, meta: meta})

      assert [input] = Floki.find(html, "input[id='flop_page_size']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["10"]
    end

    test "renders the labels and filter inputs", %{
      fields: fields,
      meta: meta
    } do
      html = render_form(%{fields: fields, meta: meta})

      # labels
      assert [label] = Floki.find(html, "label[for='flop_filters_0_value']")
      assert String.trim(Floki.text(label)) == "E-mail"
      assert [_] = Floki.find(html, "label[for='flop_filters_1_value']")

      # field inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["phone"]

      # op input
      assert [input] = Floki.find(html, "input[id='flop_filters_1_op']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["ilike"]

      # value inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_value']")
      assert Floki.attribute(input, "type") == ["text"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_value']")
      assert Floki.attribute(input, "class") == ["phone-input"]
      assert Floki.attribute(input, "type") == ["tel"]
    end

    test "renders multiple inputs for the same field", %{
      meta: meta
    } do
      fields = [
        {:email, [label: "E-mail", type: "text", class: "text-input"]},
        {:age,
         [
           label: "Minimum Age",
           op: ">=",
           type: "number",
           class: "number-input"
         ]},
        {:email, [label: "Second E-mail", type: "email", class: "email-input"]}
      ]

      html = render_form(%{fields: fields, meta: meta})

      # labels
      assert [label] = Floki.find(html, "label[for='flop_filters_0_value']")
      assert String.trim(Floki.text(label)) == "E-mail"
      assert [label] = Floki.find(html, "label[for='flop_filters_1_value']")
      assert String.trim(Floki.text(label)) == "Minimum Age"
      assert [label] = Floki.find(html, "label[for='flop_filters_2_value']")
      assert String.trim(Floki.text(label)) == "Second E-mail"

      # field inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input[id='flop_filters_2_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]

      # value inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_value']")
      assert Floki.attribute(input, "type") == ["text"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_value']")
      assert Floki.attribute(input, "type") == ["number"]
      assert [input] = Floki.find(html, "input[id='flop_filters_2_value']")
      assert Floki.attribute(input, "type") == ["email"]
    end

    test "renders multiple inputs for the same field with omitted opts", %{
      meta: meta
    } do
      fields = [
        :email,
        {:age,
         label: "Minimum Age", op: ">=", type: "number", class: "number-input"},
        {:email, label: "Second E-mail", type: "email", class: "email-input"}
      ]

      html = render_form(%{fields: fields, meta: meta})

      # labels
      assert [label] = Floki.find(html, "label[for='flop_filters_0_value']")
      assert String.trim(Floki.text(label)) == "Email"
      assert [label] = Floki.find(html, "label[for='flop_filters_1_value']")
      assert String.trim(Floki.text(label)) == "Minimum Age"
      assert [label] = Floki.find(html, "label[for='flop_filters_2_value']")
      assert String.trim(Floki.text(label)) == "Second E-mail"

      # field inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input[id='flop_filters_2_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]

      # value inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_value']")
      assert Floki.attribute(input, "type") == ["text"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_value']")
      assert Floki.attribute(input, "type") == ["number"]
      assert [input] = Floki.find(html, "input[id='flop_filters_2_value']")
      assert Floki.attribute(input, "type") == ["email"]
    end

    @tag capture_log: true
    test "renders the labels and filter inputs with errors", %{
      fields: fields
    } do
      invalid_params = %{
        "filters" => [
          %{"field" => "email", "value" => ""},
          %{"field" => "phone", "op" => "ilike", "value" => "123"}
        ],
        "page" => "0"
      }

      {:error, meta} = Flop.validate(invalid_params)

      html = render_form(%{fields: fields, meta: meta})

      # labels
      assert [label] = Floki.find(html, "label[for='flop_filters_0_value']")
      assert String.trim(Floki.text(label)) == "E-mail"
      assert [_] = Floki.find(html, "label[for='flop_filters_1_value']")

      # field inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["phone"]

      # op input
      assert [input] = Floki.find(html, "input[id='flop_filters_1_op']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["ilike"]

      # value inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_value']")
      assert Floki.attribute(input, "type") == ["text"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_value']")
      assert Floki.attribute(input, "type") == ["tel"]
    end

    test "optionally only renders existing filters", %{
      fields: fields,
      meta: meta
    } do
      meta = %{meta | flop: %Flop{filters: [%Filter{field: :phone}]}}
      html = render_form(%{dynamic: true, fields: fields, meta: meta})

      assert [label] = Floki.find(html, "label[for='flop_filters_0_value']")
      assert String.trim(Floki.text(label)) == "Phone"

      assert [] = Floki.find(html, "label[for='flop_filters_1_value']")
    end

    test "matches dynamic filters and field config correctly", %{meta: meta} do
      meta = %{
        meta
        | flop: %Flop{
            filters: [
              %Filter{field: :age, op: :>=, value: "8"},
              %Filter{field: :name, value: "George"},
              %Filter{field: :email, value: "geo"}
            ]
          }
      }

      fields = [
        {:email, label: "E-mail", type: "email", class: "email-input"},
        {:age, label: "Age", type: "number", class: "number-input"},
        :name
      ]

      html = render_form(%{dynamic: true, fields: fields, meta: meta})

      # labels
      assert [label] = Floki.find(html, "label[for='flop_filters_0_value']")
      assert String.trim(Floki.text(label)) == "Age"
      assert [label] = Floki.find(html, "label[for='flop_filters_1_value']")
      assert String.trim(Floki.text(label)) == "Name"
      assert [label] = Floki.find(html, "label[for='flop_filters_2_value']")
      assert String.trim(Floki.text(label)) == "E-mail"

      # field inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["age"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["name"]
      assert [input] = Floki.find(html, "input[id='flop_filters_2_field']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == ["email"]

      # op input
      assert [input] = Floki.find(html, "input[id='flop_filters_0_op']")
      assert Floki.attribute(input, "type") == ["hidden"]
      assert Floki.attribute(input, "value") == [">="]

      # value inputs
      assert [input] = Floki.find(html, "input[id='flop_filters_0_value']")
      assert Floki.attribute(input, "class") == ["number-input"]
      assert Floki.attribute(input, "type") == ["number"]
      assert Floki.attribute(input, "value") == ["8"]
      assert [input] = Floki.find(html, "input[id='flop_filters_1_value']")
      assert Floki.attribute(input, "type") == ["text"]
      assert Floki.attribute(input, "value") == ["George"]
      assert [input] = Floki.find(html, "input[id='flop_filters_2_value']")
      assert Floki.attribute(input, "class") == ["email-input"]
      assert Floki.attribute(input, "type") == ["email"]
      assert Floki.attribute(input, "value") == ["geo"]
    end

    test "raises error if the form is not a form for meta", %{meta: meta} do
      assert_raise ArgumentError, ~r/must be used with a filter form/, fn ->
        form_to_html(meta, fn f ->
          inputs_for(f, :filters, [fields: [:email]], fn fo ->
            render_component(&filter_fields/1, __changed__: %{}, form: fo)
          end)
        end)
      end
    end
  end

  defmodule TestBackend do
    use Flop, default_limit: 41
  end

  describe "build_path/3" do
    test "gets the backend option from the meta struct to retrieve defaults" do
      meta = %Flop.Meta{backend: TestBackend, flop: %Flop{page_size: 40}}
      assert build_path("/pets", meta) == "/pets?page_size=40"

      meta = %Flop.Meta{backend: TestBackend, flop: %Flop{page_size: 41}}
      assert build_path("/pets", meta) == "/pets"
    end

    test "gets the for option from the meta struct to retrieve defaults" do
      meta = %Flop.Meta{schema: Pet, flop: %Flop{page_size: 21}}
      assert build_path("/pets", meta) == "/pets?page_size=21"

      meta = %Flop.Meta{schema: Pet, flop: %Flop{page_size: 20}}
      assert build_path("/pets", meta) == "/pets"
    end
  end

  defmodule TestSchema do
    use Ecto.Schema

    @derive {Flop.Schema, filterable: [:email, :age], sortable: []}

    schema "test_schema" do
      field(:age, :integer)
      field(:email, :string)
    end
  end
end
