defmodule Flop.Phoenix do
  @moduledoc """
  Phoenix components for pagination, sortable tables and filter forms with
  [Flop](https://hex.pm/packages/flop).

  ## Introduction

  Please refer to the [Readme](README.md) for an introduction.

  ## Customization

  To customize the components, it is recommended to define wrapper components in
  your `CoreComponents` module that pass attributes that are constant for your
  application and add additional markup as necessary.

  For example, to customize the `pagination` component, define your own
  `pagination` component:

  ```elixir
  defmodule MyAppWeb.CoreComponents do
    use Phoenix.Component

    attr :meta, Flop.Meta, required: true
    attr :path, :any, default: nil
    attr :on_paginate, JS, default: nil
    attr :target, :string, default: nil

    attr :aria_label, :string,
      default: "Pagination",
      doc: \"""
      Aria label for the `<nav>` element. The value should be localized. In
      languages with latin characters, the first letter should be capitalized.
      If multiple pagination components are rendered on the same page, each one
      should have a distinct aria label.
      \"""

    def pagination(assigns) do
      ~H\"""
      <Flop.Phoenix.pagination
        class="pagination"
        meta={@meta}
        path={@path}
        on_paginate={@on_paginate}
        target={@target}
        aria-label={@aria_label}
        page_link_aria_label_fun={&"\#{&1}ページ目へ"}
      >
        <:previous attrs={[class: "previous"]}>
          <i class="fas fa-chevron-left"/>
        </:previous>
        <:next attrs={[class: "next"]}>
          <i class="fas fa-chevron-right"/>
        </:next>
        <:ellipsis>
          <span class="ellipsis">‥</span>
        </:ellipsis>
      </Flop.Phoenix.pagination>
      \"""
    end
  end
  ```

  Refer to the documentation of `Flop.Phoenix.pagination/1` for available
  attributes and slots on the pagination component and to `t:table_option/0` for
  a list of available options and defaults for the table component.

  ## Using links

  If the `path` attribute is set on the pagination and table component,
  pagination and sorting is handled via query parameters. You will need to
  handle those parameters in the `c:Phoenix.LiveView.handle_params/3` callback
  of your LiveView module.

      def handle_params(params, _, socket) do
        {pets, meta} = Pets.list_pets(params)
        {:noreply, assign(socket, pets: pets, meta: meta)}
      end

  ## Using JS commands

  You can pass a `Phoenix.LiveView.JS` command as `on_paginate` and `on_sort`
  attributes.

  If used with the `path` attribute, the URL will be patched _and_ the given
  JS command will be executed. This can be used to scroll to the top after a
  pagination or sorting event, for example.

  If used without the `path` attribute, you will need to include a `push`
  command to trigger an event when a pagination or sort link is clicked.

  You can set a different target with the `target` attribute, which will be used
  as `phx-target`.

  ```heex
  <Flop.Phoenix.table
    items={@items}
    meta={@meta}
    on_sort={JS.push("sort-pets")}
    target={@myself}
  />

  <Flop.Phoenix.pagination
    meta={@meta}
    on_paginate={JS.push("paginate-pets")}
    target={@myself}
  />
  ```

  You will need to handle the event in the `c:Phoenix.LiveView.handle_event/3`
  or `c:Phoenix.LiveComponent.handle_event/3` callback of your
  LiveView or LiveComponent module.

      # for page-based pagination
      def handle_event("paginate-pets", %{"page" => page}, socket) do
        flop = Flop.set_page(socket.assigns.meta.flop, page)
        {pets, meta} = Pets.list_pets(flop)
        {:noreply, assign(socket, pets: pets, meta: meta)}
      end

      # for cursor-based pagination
      def handle_event("paginate-pets", %{"to" => direction}, socket) do
        flop =
          case direction do
            :previous -> Flop.to_previous_cursor(socket.assigns.meta)
            :next -> Flop.to_next_cursor(socket.assigns.meta)
          end

        {pets, meta} = Pets.list_pets(flop)
        {:noreply, assign(socket, pets: pets, meta: meta)}
      end

      def handle_event("sort-pets", %{"order" => order}, socket) do
        flop = Flop.push_order(socket.assigns.meta.flop, order)
        {pets, meta} = Pets.list_pets(flop)
        {:noreply, assign(socket, pets: pets, meta: meta)}
      end
  """

  use Phoenix.Component

  import Phoenix.HTML.Form,
    only: [
      input_id: 2,
      input_name: 2
    ]

  alias Flop.Meta
  alias Flop.Phoenix.Misc
  alias Flop.Phoenix.Pagination
  alias Flop.Phoenix.Table
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS
  alias Plug.Conn.Query

  @typedoc """
  Defines how many page links to render.

  - `:all` - Renders all page links.
  - `:none` - Does not render any page links.
  - Integer - Renders up to the specified number of page links in addition to
    the first and last page.
  """
  @type page_link_option :: :all | :none | pos_integer

  @typedoc """
  Defines the available options for `Flop.Phoenix.table/1`.

  - `:container` - Wraps the table in a `<div>` if `true`.
    Default: `#{inspect(Table.default_opts()[:container])}`.
  - `:container_attrs` - The attributes for the table container.
    Default: `#{inspect(Table.default_opts()[:container_attrs])}`.
  - `:no_results_content` - Any content that should be rendered if there are no
    results. Default: `<p>No results.</p>`.
  - `:table_attrs` - The attributes for the `<table>` element.
    Default: `#{inspect(Table.default_opts()[:table_attrs])}`.
  - `:symbol_asc` - The symbol that is used to indicate that the column is
    sorted in ascending order.
    Default: `#{inspect(Table.default_opts()[:symbol_asc])}`.
  - `:symbol_attrs` - The attributes for the `<span>` element that wraps the
    order direction indicator in the header columns.
    Default: `#{inspect(Table.default_opts()[:symbol_attrs])}`.
  - `:symbol_desc` - The symbol that is used to indicate that the column is
    sorted in ascending order.
    Default: `#{inspect(Table.default_opts()[:symbol_desc])}`.
  - `:symbol_unsorted` - The symbol that is used to indicate that the column is
    not sorted. Default: `#{inspect(Table.default_opts()[:symbol_unsorted])}`.
  - `:tbody_attrs`: Attributes to be added to the `<tbody>` tag within the
    `<table>`. Default: `#{inspect(Table.default_opts()[:tbody_attrs])}`.
  - `:tbody_td_attrs`: Attributes to be added to each `<td>` tag within the
    `<tbody>`. Default: `#{inspect(Table.default_opts()[:tbody_td_attrs])}`.
  - `:thead_attrs`: Attributes to be added to the `<thead>` tag within the
    `<table>`. Default: `#{inspect(Table.default_opts()[:thead_attrs])}`.
  - `:tbody_tr_attrs`: Attributes to be added to each `<tr>` tag within the
    `<tbody>`. A function with arity of 1 may be passed to dynamically generate
    the attrs based on row data.
    Default: `#{inspect(Table.default_opts()[:tbody_tr_attrs])}`.
  - `:thead_th_attrs`: Attributes to be added to each `<th>` tag within the
    `<thead>`. Default: `#{inspect(Table.default_opts()[:thead_th_attrs])}`.
  - `:thead_tr_attrs`: Attributes to be added to each `<tr>` tag within the
    `<thead>`. Default: `#{inspect(Table.default_opts()[:thead_tr_attrs])}`.
  """
  @type table_option ::
          {:container, boolean}
          | {:container_attrs, keyword}
          | {:no_results_content, Phoenix.HTML.safe() | binary}
          | {:symbol_asc, Phoenix.HTML.safe() | binary}
          | {:symbol_attrs, keyword}
          | {:symbol_desc, Phoenix.HTML.safe() | binary}
          | {:symbol_unsorted, Phoenix.HTML.safe() | binary}
          | {:table_attrs, keyword}
          | {:tbody_attrs, keyword}
          | {:thead_attrs, keyword}
          | {:tbody_td_attrs, keyword}
          | {:tbody_tr_attrs, keyword | (any -> keyword)}
          | {:thead_th_attrs, keyword}
          | {:thead_tr_attrs, keyword}

  @doc """
  Renders pagination links for the given `Flop.Meta` struct.

  This component can render both page-based or cursor-based pagination links.
  Which one is used depends on the pagination type that was used to make the
  Flop query.

  ## Examples

  With a verified route:

  ```heex
  <Flop.Phoenix.pagination
    meta={@meta}
    path={~p"/pets"}
  />
  ```

  With an event:

  ```heex
  <Flop.Phoenix.pagination
    meta={@meta}
    on_paginate={JS.push("paginate")}
  />
  ```

  With a route helper:

  ```heex
  <Flop.Phoenix.pagination
    meta={@meta}
    path={{Routes, :pet_path, [@socket, :index]}}
  />
  ```

  With all attributes and slots:

  ```heex
  <Flop.Phoenix.pagination
    meta={@meta}
    path={~p"/pets"}
    on_paginate={JS.dispatch("my_app:scroll_to", to: "#pet-table")}
    target={@myself}
    class="pagination"
    page_link_aria_label_fun={&"\#{&1}ページ目へ"}
    page_links={5}
    page_list_attrs={[class: "pagination-list"]}
    page_list_item_attrs={[class: "pagination-item"]}
    page_link_attrs={[class: "pagination-link"]}
    current_page_link_attrs={[class: "pagination-link is-current"]}
    disabled_link_attrs={[class: "is-disabled"]}
    reverse
  >
    <:previous attrs={[class: "pagination-previous"]}>
      Previous
    </:previous>
    <:next attrs={[class: "pagination-next"]}>
      Next
    </:next>
    <:ellipsis>
      <span class="pagination-ellipsis" aria-hidden="true">&hellip;</span>
    </:ellipsis>
  </Flop.Phoenix.pagination>
  ```
  """
  @doc section: :components
  @spec pagination(map) :: Phoenix.LiveView.Rendered.t()

  attr :meta, Flop.Meta,
    required: true,
    doc: """
    The meta information of the query as returned by the `Flop` query functions.
    """

  attr :path, :any,
    default: nil,
    doc: """
    If set, the current view is patched with updated query parameters when a
    pagination link is clicked. In case the `on_paginate` attribute is set as
    well, the URL is patched _and_ the given command is executed.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `Flop.Phoenix.build_path/3` for details.
    """

  attr :on_paginate, JS,
    default: nil,
    doc: """
    A `Phoenix.LiveView.JS` command that is triggered when a pagination link is
    clicked.

    If used without the `path` attribute, you should include a `push` operation
    to handle the event with the `handle_event` callback.

    ```heex
    <.pagination
      meta={@meta}
      on_paginate={
        JS.dispatch("my_app:scroll_to", to: "#pet-table") |> JS.push("paginate")
      }
    />
    ```

    If used with the `path` attribute, the URL is patched _and_ the given
    JS command is executed.

    ```heex
    <.pagination
      meta={@meta}
      path={~p"/pets"}
      on_paginate={JS.dispatch("my_app:scroll_to", to: "#pet-table")}
    />
    ```

    With the above attributes in place, you can add the following JavaScript to
    your application to scroll to the top of your table whenever a pagination
    link is clicked:

    ```js
    window.addEventListener("my_app:scroll_to", (e) => {
      e.target.scrollIntoView();
    });
    ```

    You can use CSS to scroll to the new position smoothly.

    ```css
    html {
      scroll-behavior: smooth;
    }
    ```
    """

  attr :target, :string,
    default: nil,
    doc: """
    Sets the `phx-target` attribute for the pagination links.
    """

  attr :page_link_aria_label_fun, {:fun, 1},
    doc: """
    Function that returns an aria label for the page link or button to the
    given page number.

    The returned label should be localized and start with a capital letter.
    """,
    default: &Flop.Phoenix.page_link_aria_label/1

  attr :page_links, :any,
    default: 5,
    doc: """
    Defines how many page links to render.

    - `:all` - Renders all page links.
    - `:none` - Does not render any page links.
    - Integer - Renders up to the specified number of page links in addition to
      the first and last page.

    This attribute is only used for page-based pagination.
    """

  attr :reverse, :boolean,
    default: false,
    doc: """
    By default, the `next` link moves forward with the `:after` parameter set to
    the end cursor, and the `previous` link moves backward with the `:before`
    parameter set to the start cursor. If `reverse` is set to `true`, the
    destinations of the links are switched.

    This attribute is only for cursor-based pagination.
    """

  attr :page_list_attrs, :list,
    default: [],
    doc: """
    Attributes to be added to the `<ul>` that contains the page links.
    """

  attr :page_list_item_attrs, :list,
    default: [],
    doc: """
    Attributes to be added to the `<li>` elements that contain the page links.
    """

  attr :page_link_attrs, :list,
    default: [],
    doc: """
    Attributes to be added to the page links or buttons.

    These attributes are not applied to previous links, next links, or the
    current page link.
    """

  attr :current_page_link_attrs, :list,
    default: [],
    doc: """
    Attributes to be added to the current page link or button.

    Note that the `aria-current` attribute is automatically set.

    It is recommended to define CSS styles using the `[aria-current="page"]`
    selector instead of using a class.
    """

  attr :disabled_link_attrs, :list,
    default: [],
    doc: """
    Attributes to be added to disabled previous/next links or buttons.

    If a `class` is set, it is merged with the class set on the previous/next
    slot.

    Note that the `disabled` attribute is automatically set for buttons and the
    `aria-disabled="true"` attribute is automatically set for links.

    It is recommended to define CSS styles using the
    `[disabled], [aria-disabled="true"]` selector instead of using a class.
    """

  attr :rest, :global,
    default: %{"aria-label": "Pagination"},
    doc: """
    The attributes are added to the outer `<nav>` element.


    The `aria-label` defaults to `"Pagination"`. If your application is
    localized, the label should be translated to the user locale. In languages
    with latin characters, the first letter should be capitalized. If multiple
    pagination components are rendered on the same page, each one should have
    a distinct aria label.
    """

  slot :previous,
    doc: """
    The content of the pagination link or button to the previous page.

    If the slot is not used, the text "Previous" is rendered.
    """ do
    attr :attrs, :list,
      doc: """
      Any additional attributes to add to the link or button.

      Defaults to `[aria: [label: "Go to previous page"]]`.
      """
  end

  slot :next,
    doc: """
    The content of the pagination link or button to the next page.

    If the slot is not used, the text "Next" is rendered.
    """ do
    attr :attrs, :list,
      doc: """
      Any additional attributes to add to the link or button.

      Defaults to `[aria: [label: "Go to next page"]]`.
      """
  end

  slot :ellipsis,
    doc: """
    The content of the `<li>` element that usually shows an ellipsis and is
    rendered toward the beginning and/or end of the page links if there are
    more pages than the configured limit.

    If the slot is not used, a default element is used:

    ```html
    <span aria-hidden="true">&hellip;</span>
    ```
    """

  def pagination(%{path: nil, on_paginate: nil}) do
    raise Flop.Phoenix.PathOrJSError, component: :pagination
  end

  def pagination(%{previous: previous, next: next} = assigns) do
    # Unpack previous and next slot attributes. We can't use :for attribute
    # because the slot is optional.
    previous_attrs =
      case previous do
        [%{attrs: attrs}] -> attrs
        _ -> [aria: [label: "Go to previous page"]]
      end

    next_attrs =
      case next do
        [%{attrs: attrs}] -> attrs
        _ -> [aria: [label: "Go to next page"]]
      end

    assigns =
      assign(assigns, previous_attrs: previous_attrs, next_attrs: next_attrs)

    ~H"""
    <.pagination_for
      :let={p}
      meta={@meta}
      page_links={@page_links}
      path={@path}
      reverse={@reverse}
    >
      <nav {@rest}>
        <.pagination_link
          :if={p.pagination_type in [:page, :offset]}
          disabled={is_nil(p.previous_page)}
          disabled_link_attrs={@disabled_link_attrs}
          target={@target}
          page={p.previous_page}
          path={p.path_fun.(p.previous_page)}
          on_paginate={@on_paginate}
          rel="prev"
          {@previous_attrs}
        >
          {render_slot(@previous) || "Previous"}
        </.pagination_link>
        <.pagination_link
          :if={p.pagination_type in [:page, :offset]}
          disabled={is_nil(p.next_page)}
          disabled_link_attrs={@disabled_link_attrs}
          target={@target}
          page={p.next_page}
          path={p.path_fun.(p.next_page)}
          on_paginate={@on_paginate}
          rel="next"
          {@next_attrs}
        >
          {render_slot(@next) || "Next"}
        </.pagination_link>
        <.page_links
          :if={p.pagination_type in [:page, :offset] and @page_links != :none}
          current_page={p.current_page}
          ellipsis={@ellipsis}
          ellipsis_end?={p.ellipsis_end?}
          ellipsis_start?={p.ellipsis_start?}
          on_paginate={@on_paginate}
          page_link_aria_label_fun={@page_link_aria_label_fun}
          path_fun={p.path_fun}
          page_range_end={p.page_range_end}
          page_range_start={p.page_range_start}
          target={@target}
          total_pages={p.total_pages}
          page_list_item_attrs={@page_list_item_attrs}
          page_link_attrs={@page_link_attrs}
          current_page_link_attrs={@current_page_link_attrs}
          {@page_list_attrs}
        />
        <.pagination_link
          :if={p.pagination_type in [:first, :last]}
          direction={p.previous_direction}
          path={p.path_fun.(p.previous_cursor, p.previous_direction)}
          on_paginate={@on_paginate}
          target={@target}
          disabled={is_nil(p.previous_cursor)}
          disabled_link_attrs={@disabled_link_attrs}
          rel="prev"
          {@previous_attrs}
        >
          {render_slot(@previous) || "Previous"}
        </.pagination_link>
        <.pagination_link
          :if={p.pagination_type in [:first, :last]}
          direction={p.next_direction}
          path={p.path_fun.(p.next_cursor, p.next_direction)}
          on_paginate={@on_paginate}
          target={@target}
          disabled={is_nil(p.next_cursor)}
          disabled_link_attrs={@disabled_link_attrs}
          rel="next"
          {@next_attrs}
        >
          {render_slot(@next) || "Next"}
        </.pagination_link>
      </nav>
    </.pagination_for>
    """
  end

  attr :current_page, :integer, required: true
  attr :ellipsis_end?, :boolean, required: true
  attr :ellipsis_start?, :boolean, required: true
  attr :on_paginate, JS
  attr :page_list_item_attrs, :list, required: true
  attr :page_link_attrs, :list, required: true
  attr :current_page_link_attrs, :list, required: true
  attr :page_link_aria_label_fun, {:fun, 1}, required: true
  attr :path_fun, :any, required: true
  attr :page_range_end, :integer, required: true
  attr :page_range_start, :integer, required: true
  attr :target, :string, required: true
  attr :total_pages, :integer, required: true
  attr :ellipsis, :any
  attr :rest, :global

  defp page_links(assigns) do
    ~H"""
    <ul {@rest}>
      <li :if={@page_range_start > 1} {@page_list_item_attrs}>
        <.pagination_link
          target={@target}
          page={1}
          path={@path_fun.(1)}
          on_paginate={@on_paginate}
          aria-label={@page_link_aria_label_fun.(1)}
          {(@current_page != 1 && @page_link_attrs) || []}
          {(@current_page == 1 && @current_page_link_attrs) || []}
        >
          1
        </.pagination_link>
      </li>

      <li :if={@ellipsis_start?} {@page_list_item_attrs}>
        <.ellipsis ellipsis={@ellipsis} />
      </li>

      <li :for={page <- @page_range_start..@page_range_end} {@page_list_item_attrs}>
        <.pagination_link
          target={@target}
          page={page}
          path={@path_fun.(page)}
          on_paginate={@on_paginate}
          aria-current={@current_page == page && "page"}
          aria-label={@page_link_aria_label_fun.(page)}
          {(@current_page != page && @page_link_attrs) || []}
          {(@current_page == page && @current_page_link_attrs) || []}
        >
          {page}
        </.pagination_link>
      </li>

      <li :if={@ellipsis_end?} {@page_list_item_attrs}>
        <.ellipsis ellipsis={@ellipsis} />
      </li>

      <li :if={@page_range_end < @total_pages} {@page_list_item_attrs}>
        <.pagination_link
          target={@target}
          page={@total_pages}
          path={@path_fun.(@total_pages)}
          on_paginate={@on_paginate}
          aria-label={@page_link_aria_label_fun.(@total_pages)}
          {(@current_page != @total_pages && @page_link_attrs) || []}
          {(@current_page == @total_pages && @current_page_link_attrs) || []}
        >
          {@total_pages}
        </.pagination_link>
      </li>
    </ul>
    """
  end

  defp ellipsis(%{ellipsis: []} = assigns) do
    ~H"""
    <span aria-hidden="true">&hellip;</span>
    """
  end

  defp ellipsis(assigns) do
    ~H"""
    {render_slot(@ellipsis)}
    """
  end

  attr :path, :string
  attr :on_paginate, JS
  attr :target, :string, required: true
  attr :page, :integer, default: nil
  attr :direction, :atom, default: nil
  attr :disabled, :boolean, default: false
  attr :disabled_link_attrs, :list, default: []
  attr :rel, :string, default: nil
  attr :rest, :global
  slot :inner_block

  defp pagination_link(
         %{
           disabled: true,
           disabled_link_attrs: disabled_link_attrs,
           path: nil,
           rest: rest
         } = assigns
       ) do
    {class, disabled_link_attrs} = Keyword.pop(disabled_link_attrs, :class)

    rest =
      Map.update(rest, :class, class, fn default_class ->
        merge_classes(default_class, class)
      end)

    assigns =
      assign(assigns, disabled_link_attrs: disabled_link_attrs, rest: rest)

    ~H"""
    <button disabled {@disabled_link_attrs} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp pagination_link(
         %{
           disabled: true,
           disabled_link_attrs: disabled_link_attrs,
           rest: rest
         } =
           assigns
       ) do
    # Disabled state of the link is expressed by omission of the href attribute
    # and addition of aria-disabled attribute. Links without href do not
    # implicitly have the role "link", so it needs to be added as an attribute.
    #
    # https://www.w3.org/TR/html-aria/#docconformance
    # https://www.w3.org/TR/html-aria/#example-communicate-a-disabled-link-with-aria

    {class, disabled_link_attrs} = Keyword.pop(disabled_link_attrs, :class)

    rest =
      Map.update(rest, :class, class, fn default_class ->
        merge_classes(default_class, class)
      end)

    assigns =
      assign(assigns, disabled_link_attrs: disabled_link_attrs, rest: rest)

    ~H"""
    <a role="link" aria-disabled="true" {@disabled_link_attrs} {@rest}>
      {render_slot(@inner_block)}
    </a>
    """
  end

  defp pagination_link(%{on_paginate: nil, path: path} = assigns)
       when is_binary(path) do
    ~H"""
    <.link patch={@path} rel={@rel} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp pagination_link(%{on_paginate: on_paginate, path: nil} = assigns)
       when not is_nil(on_paginate) do
    ~H"""
    <button
      phx-click={@on_paginate}
      phx-target={@target}
      phx-value-page={@page}
      phx-value-to={@direction}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp pagination_link(assigns) do
    ~H"""
    <.link
      patch={@path}
      rel={@rel}
      phx-click={@on_paginate}
      phx-target={@target}
      phx-value-page={@page}
      phx-value-to={@direction}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp merge_classes(nil, class), do: class
  defp merge_classes(class, nil), do: class
  defp merge_classes([_ | _] = a, [_ | _] = b), do: a ++ b
  defp merge_classes([_ | _] = a, b), do: a ++ [b]
  defp merge_classes(a, [_ | _] = b), do: [a] ++ b
  defp merge_classes(a, b), do: [a, b]

  @doc """
  Returns an aria label for a link to the given page number.

  This is the default function used by `pagination/1`.

  ## Example

      iex> page_link_aria_label(5)
      "Go to page 5"
  """
  @spec page_link_aria_label(integer) :: String.t()
  def page_link_aria_label(n) when is_integer(n) do
    "Go to page #{n}"
  end

  @doc """
  This component is a pagination builder.

  It does not render anything by itself. Instead, it prepares all the necessary
  information needed to render a pagination component and passes it to the
  inner block.

  For an example implementation, see `pagination/1`.

  ## Example

  ```heex
  <.pagination_for
    :let={p}
    meta={@meta}
    page_links={4}
    path={~p"/birds"}
  >
    <%!-- put together your component here --%>
  </.pagination_for>
  ```

  The variable passed to the inner block is a `Flop.Phoenix.Pagination` struct.
  """
  @doc section: :components
  @doc since: "0.24.0"
  @spec pagination_for(map) :: Phoenix.LiveView.Rendered.t()

  attr :meta, Flop.Meta,
    required: true,
    doc: """
    The meta information of the query as returned by the `Flop` query functions.
    """

  attr :path, :any,
    default: nil,
    doc: """
    If set, a function that takes a page number and returns a link with
    pagination, filter, and sort parameters based on the given path is passed
    as `path_fun` to the inner block.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `Flop.Phoenix.build_path/3` for details.
    """

  attr :page_links, :any,
    default: 5,
    doc: """
    Defines how many page links to render.

    - `:all` - Renders all page links.
    - `:none` - Does not render any page links.
    - Integer - Renders up to the specified number of page links in addition to
      the first and last page.

    A `page_range_start` and `page_range_end` attribute are passed to the
    inner block based on this option. If this attribute is set to `:none`, both
    of those values will be `nil`.
    """

  attr :reverse, :boolean,
    default: false,
    doc: """
    By default, the `next` link moves forward with the `:after` parameter set to
    the end cursor, and the `previous` link moves backward with the `:before`
    parameter set to the start cursor. If `reverse` is set to `true`, the
    destinations of the links are switched.
    """

  slot :inner_block, required: true

  def pagination_for(
        %{
          meta:
            %Flop.Meta{
              errors: [],
              has_next_page?: has_next_page?,
              has_previous_page?: has_previous_page?
            } = meta,
          page_links: page_links,
          path: path,
          reverse: reverse
        } = assigns
      )
      when has_next_page? or has_previous_page? do
    pagination =
      Pagination.new(meta, page_links: page_links, path: path, reverse: reverse)

    assigns =
      assigns
      |> assign(:pagination, pagination)
      |> assign(:meta, nil)
      |> assign(:page_links, nil)
      |> assign(:path, nil)

    ~H"""
    {render_slot(@inner_block, @pagination)}
    """
  end

  def pagination_for(assigns) do
    ~H""
  end

  @doc """
  Returns the range of page links to be rendered.

  ## Usage

      iex> page_link_range(:all, 4, 20)
      {1, 20}

      iex> page_link_range(:none, 4, 20)
      {nil, nil}

      iex> page_link_range(5, 4, 20)
      {2, 6}
  """
  @doc since: "0.24.0"
  @spec page_link_range(page_link_option(), pos_integer(), pos_integer()) ::
          {pos_integer() | nil, pos_integer() | nil}
  def page_link_range(:all, _, total_pages), do: {1, total_pages}
  def page_link_range(:none, _, _), do: {nil, nil}

  def page_link_range(max_pages, current_page, total_pages)
      when is_integer(max_pages) do
    # number of additional pages to show before or after current page
    additional = ceil(max_pages / 2)

    cond do
      max_pages >= total_pages ->
        {1, total_pages}

      current_page + additional > total_pages ->
        {total_pages - max_pages + 1, total_pages}

      true ->
        first = max(current_page - additional + 1, 1)
        last = min(first + max_pages - 1, total_pages)
        {first, last}
    end
  end

  @doc """
  Generates a table with sortable columns.

  ## Example

  ```heex
  <Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
    <:col :let={pet} label="Name" field={:name}>{pet.name}</:col>
    <:col :let={pet} label="Age" field={:age}>{pet.age}</:col>
  </Flop.Phoenix.table>
  ```

  ## Flop.Schema

  If you pass the `for` option when making the query with Flop, Flop Phoenix can
  determine which table columns are sortable. It also hides the `order` and
  `page_size` parameters if they match the default values defined with
  `Flop.Schema`.
  """
  @doc since: "0.6.0"
  @doc section: :components
  @spec table(map) :: Phoenix.LiveView.Rendered.t()

  attr :id, :string,
    doc: """
    ID used on the table. If not set, an ID is chosen based on the schema
    module derived from the `Flop.Meta` struct.

    The ID is necessary in case the table is fed with a LiveView stream.
    """

  attr :items, :list,
    required: true,
    doc: """
    The list of items to be displayed in rows. This is the result list returned
    by the query.
    """

  attr :meta, Flop.Meta,
    required: true,
    doc: "The `Flop.Meta` struct returned by the query function."

  attr :path, :any,
    default: nil,
    doc: """
    If set, the current view is patched with updated query parameters when a
    header link for sorting is clicked. In case the `on_sort` attribute is
    set as well, the URL is patched _and_ the given JS command is executed.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `Flop.Phoenix.build_path/3` for details.
    """

  attr :on_sort, JS,
    default: nil,
    doc: """
    A `Phoenix.LiveView.JS` command that is triggered when a header link for
    sorting is clicked.

    If used without the `path` attribute, you should include a `push` operation
    to handle the event with the `handle_event` callback.

    ```heex
    <.table
      items={@items}
      meta={@meta}
      on_sort={
        JS.dispatch("my_app:scroll_to", to: "#pet-table") |> JS.push("sort")
      }
    />
    ```

    If used with the `path` attribute, the URL is patched _and_ the given
    JS command is executed.

    ```heex
    <.table
      meta={@meta}
      path={~p"/pets"}
      on_sort={JS.dispatch("my_app:scroll_to", to: "#pet-table")}
    />
    ```
    """

  attr :target, :string,
    default: nil,
    doc: "Sets the `phx-target` attribute for the header links."

  attr :caption, :string,
    default: nil,
    doc: "Content for the `<caption>` element."

  attr :opts, :list,
    default: [],
    doc: """
    Keyword list with additional options (see `t:Flop.Phoenix.table_option/0`).
    Note that the options passed to the function are deep merged into the
    default options. Since these options will likely be the same for all the
    tables in a project, it is recommended to define them once in a function or
    set them in a wrapper function as described in the `Customization` section
    of the module documentation.
    """

  attr :row_id, :any,
    default: nil,
    doc: """
    Overrides the default function that retrieves the row ID from a stream item.
    """

  attr :row_click, :any,
    default: nil,
    doc: """
    Sets the `phx-click` function attribute for each row `td`. Expects to be a
    function that receives a row item as an argument. This does not add the
    `phx-click` attribute to the `action` slot.

    Example:

    ```heex
    row_click={&JS.navigate(~p"/users/\#{&1}")}
    ```
    """

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: """
    This function is called on the row item before it is passed to the :col
    and :action slots.
    """

  slot :col,
    required: true,
    doc: """
    For each column to render, add one `<:col>` element.

    ```heex
    <:col :let={pet} label="Name" field={:name} col_style="width: 20%;">
      {pet.name}
    </:col>
    ```

    Any additional assigns will be added as attributes to the `<td>` elements.

    """ do
    attr :label, :any, doc: "The content for the header column."

    attr :field, :atom,
      doc: """
      The field name for sorting. If set and the field is configured as sortable
      in the schema, the column header will be clickable, allowing the user to
      sort by that column. If the field is not marked as sortable or if the
      `field` attribute is omitted or set to `nil` or `false`, the column header
      will not be clickable.
      """

    attr :directions, :any,
      doc: """
      An optional 2-element tuple used for custom ascending and descending sort
      behavior for the column, i.e. `{:asc_nulls_last, :desc_nulls_first}`
      """

    attr :col_style, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_style` assign is set as `style` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :col_class, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_class` assign is set as `class` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :thead_th_attrs, :list,
      doc: """
      Additional attributes to pass to the `<th>` element as a static keyword
      list. Note that these attributes will override any conflicting
      `thead_th_attrs` that are set at the table level.
      """

    attr :tbody_td_attrs, :any,
      doc: """
      Additional attributes to pass to the `<td>` element. May be provided as a
      static keyword list, or as a 1-arity function to dynamically generate the
      list using row data. Note that these attributes will override any
      conflicting `tbody_td_attrs` that are set at the table level.
      """
  end

  slot :action,
    doc: """
    The slot for showing user actions in the last table column. These columns
    do not receive the `row_click` attribute.


    ```heex
    <:action :let={user}>
      <.link navigate={~p"/users/\#{user}"}>Show</.link>
    </:action>
    ```
    """ do
    attr :label, :string, doc: "The content for the header column."

    attr :col_style, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_style` assign is set as `style` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :col_class, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_class` assign is set as `class` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :thead_th_attrs, :list,
      doc: """
      Any additional attributes to pass to the `<th>` as a keyword list.
      """

    attr :tbody_td_attrs, :any,
      doc: """
      Any additional attributes to pass to the `<td>`. Can be a keyword list or
      a function that takes the current row item as an argument and returns a
      keyword list.
      """
  end

  slot :foot,
    doc: """
    You can optionally add a `foot`. The inner block will be rendered inside
    a `tfoot` element.

    ```heex
    <Flop.Phoenix.table>
      <:foot>
        <tr><td>Total: <span class="total">{@total}</span></td></tr>
      </:foot>
    </Flop.Phoenix.table>
    ```
    """

  slot :head,
    doc: """
    You can optionally add a 2nd `head`. The inner block will be rendered inside
    the `thead` element and below the table header of the `col` slots.

    ```heex
    <Flop.Phoenix.table>
      <:head>
        <tr><td>Total: <span class="total">{@total}</span></td></tr>
      </:head>
    </Flop.Phoenix.table>
    ```
    """

  def table(%{path: nil, on_sort: nil}) do
    raise Flop.Phoenix.PathOrJSError, component: :table
  end

  def table(%{meta: meta, opts: opts} = assigns) do
    assigns =
      assigns
      |> assign(:opts, Table.merge_opts(opts))
      |> assign_new(:id, fn -> table_id(meta.schema) end)

    ~H"""
    <%= if @items == [] do %>
      {@opts[:no_results_content]}
    <% else %>
      <%= if @opts[:container] do %>
        <div id={@id <> "-container"} {@opts[:container_attrs]}>
          <Table.render
            caption={@caption}
            col={@col}
            foot={@foot}
            head={@head}
            on_sort={@on_sort}
            id={@id}
            items={@items}
            meta={@meta}
            opts={@opts}
            path={@path}
            target={@target}
            row_id={@row_id}
            row_click={@row_click}
            row_item={@row_item}
            action={@action}
          />
        </div>
      <% else %>
        <Table.render
          caption={@caption}
          col={@col}
          foot={@foot}
          head={@head}
          on_sort={@on_sort}
          id={@id}
          items={@items}
          meta={@meta}
          opts={@opts}
          path={@path}
          target={@target}
          row_id={@row_id}
          row_click={@row_click}
          row_item={@row_item}
          action={@action}
        />
      <% end %>
    <% end %>
    """
  end

  defp table_id(nil), do: "sortable-table"

  defp table_id(schema) do
    module_name = schema |> Module.split() |> List.last() |> Macro.underscore()
    module_name <> "-table"
  end

  @doc """
  Renders all inputs for a filter form including the hidden inputs.

  ## Example

      def filter_form(%{meta: meta} = assigns) do
        assigns = assign(assigns, :form, Phoenix.Component.to_form(meta))

        ~H\"""
        <.form for={@form}>
          <.filter_fields :let={i} form={@form} fields={[:email, :name]}>
            <.input
              field={i.field}
              label={i.label}
              type={i.type}
              {i.rest}
            />
          </.filter_fields>
        </.form>
        \"""
      end

  This assumes that you have defined an `input` component that renders a form
  input including the label.

  These options are passed to the inner block via `:let`:

  - The `field` is a `Phoenix.HTML.FormField` struct.
  - The `type` is the input type as a string (e.g. `"text"`, `"number"`). The
    type is derived from the type of the field being filtered on, but it can
    be overridden in the field options.
  - `rest` contains any additional field options passed.

  ## Field configuration

  The fields can be passed as atoms or keywords with additional options.

      fields={[:name, :email]}

  Or

      fields={[
        name: [label: gettext("Name")],
        email: [
          label: gettext("Email"),
          op: :ilike_and,
          type: "email"
        ],
        age: [
          label: gettext("Age"),
          type: "select",
          prompt: "",
          options: [
            {gettext("young"), :young},
            {gettext("old"), :old)}
          ]
        ]
      ]}

  Available options:

  - `label` - Defaults to the humanized field name.
  - `op` - Defaults to `:==`.
  - `type` - Defaults to an input type depending on the Ecto type of the filter
    field.

  Any additional options will be passed to the input component (e.g. HTML
  classes or a list of options).
  """
  @doc since: "0.12.0"
  @doc section: :components
  @spec filter_fields(map) :: Phoenix.LiveView.Rendered.t()

  attr :form, Phoenix.HTML.Form, required: true

  attr :fields, :list,
    default: [],
    doc: """
    The list of fields and field options. Note that inputs will not be rendered
    for fields that are not marked as filterable in the schema
    (see `Flop.Schema`).

    If `dynamic` is set to `false`, only fields in this list are rendered. If
    `dynamic` is set to `true`, only fields for filters present in the given
    `Flop.Meta` struct are rendered, and the fields are rendered even if they
    are not passed in the `fields` list. In the latter case, `fields` is
    optional, but you can still pass label and input configuration this way.

    Note that in a dynamic form, it is not possible to configure a single field
    multiple times.
    """

  attr :dynamic, :boolean,
    default: false,
    doc: """
    If `true`, fields are only rendered for filters that are present in the
    `Flop.Meta` struct passed to the form. You can use this for rendering filter
    forms that allow the user to add and remove filters dynamically. The
    `fields` assign is only used for looking up the options in that case.
    """

  slot :inner_block,
    doc: """
    The necessary options for rendering a label and an input are passed to the
    inner block, which allows you to render the fields with your existing
    components.

    ```heex
    <.filter_fields :let={i} form={@form} fields={[:email, :name]}>
      <.input
        field={i.field}
        label={i.label}
        type={i.type}
        {i.rest}
      />
    </.filter_fields>
    ```

    The options passed to the inner block are:

    - `field` - A `Phoenix.HTML.FormField` struct.
    - `type` - The input type as a string.
    - `label` - The label text as a string.
    - `rest` - Any additional options passed in the field options.
    """

  def filter_fields(assigns) do
    ensure_meta_form!(assigns.form)

    assigns =
      assign(assigns, :fields, normalize_filter_fields(assigns[:fields] || []))

    ~H"""
    <.hidden_inputs_for_filter form={@form} />
    <.inputs_for
      :let={ff}
      field={@form[:filters]}
      options={[dynamic: @dynamic, fields: @fields]}
    >
      <.hidden_inputs_for_filter form={ff} />
      {render_slot(@inner_block, %{
        field: ff[:value],
        label: ff.options[:label],
        type: ff.options[:type],
        rest: Keyword.drop(ff.options, [:label, :op, :type])
      })}
    </.inputs_for>
    """
  end

  defp normalize_filter_fields(fields) do
    Enum.map(fields, fn
      field when is_atom(field) ->
        {field, []}

      {field, opts} when is_atom(field) and is_list(opts) ->
        {field, opts}

      field ->
        raise Flop.Phoenix.InvalidFilterFieldConfigError, value: field
    end)
  end

  defp ensure_meta_form!(%Form{data: %Flop{}, source: %Meta{}}), do: :ok
  defp ensure_meta_form!(_), do: raise(Flop.Phoenix.NoMetaFormError)

  @doc """
  Renders hidden inputs for the given form.

  You can use this for convenience if you have a complex form layout that cannot
  be accomplished with `Flop.Phoenix.filter_fields/1`. Put it as a direct child
  of the `form` component to render the hidden inputs for pagination and order
  parameters. Then use `Phoenix.Component.inputs_for/1` to render a single
  filter field, and place this component within the anonymous function to render
  the hidden inputs for the filter field and operator.

  Since the filters are represented as an array in the params, make sure to
  add the `offset` option so that the `Flop.Meta` can be properly mapped back to
  your input fields. For every call to `inputs_for` always add the length of all
  previous calls to `inputs_for` as offset. Note that the example below uses
  the old `Phoenix.Component.inputs_for/1` function.
  Also don't forget to set the `skip_persistent_id` attribute
  to prevent LiveView from overriding the IDs and causing duplicate DOM IDs.

  ```heex
  <.form :let={f} for={@meta}>
    <.hidden_inputs_for_filter form={@form} />

    <div class="field-group">
      <div class="field">
        <.inputs_for
          :let={ff}
          field={f[:filters]}
          options={[fields: [:name]]}
          skip_persistent_id
        >
          <.hidden_inputs_for_filter form={ff} />
          <.input label="Name" type="text" field={ff[:value]} />
        </.inputs_for>
      </div>
      <div class="field">
        <.inputs_for
          :let={ff}
          field={f[:filters]}
          options={[fields: [email: [op: :ilike]], offset: 1]}
          skip_persistent_id
        >
          <.hidden_inputs_for_filter form={ff} />
          <.input label="E-mail" type="email" field={ff[:value]} />
        </.inputs_for>
      </div>
    </div>
  </.form>
  ```
  """
  @doc since: "0.16.0"
  @doc section: :components

  attr :form, Phoenix.HTML.Form, required: true

  def hidden_inputs_for_filter(assigns) do
    ~H"""
    <.hidden_inputs
      :for={{field, value} <- @form.hidden}
      form={@form}
      field={field}
      value={value}
    />
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :field, :atom, required: true
  attr :value, :any, required: true

  defp hidden_inputs(%{value: value} = assigns) when is_list(value) do
    ~H"""
    <input
      :for={{v, index} <- Enum.with_index(@value)}
      type="hidden"
      id={input_id(@form, @field) <> "_#{index}"}
      name={input_name(@form, @field) <> "[]"}
      value={v}
      hidden
    />
    """
  end

  defp hidden_inputs(assigns) do
    ~H"""
    <input
      type="hidden"
      id={input_id(@form, @field)}
      name={input_name(@form, @field)}
      value={@value}
      hidden
    />
    """
  end

  @doc """
  Converts a Flop struct into a keyword list that can be used as a query with
  Phoenix verified routes or route helper functions.

  ## Default parameters

  Default parameters for the limit and order parameters are omitted. The
  defaults are determined by calling `Flop.get_option/3`.

  - Pass the `:for` option to pick up the default values from a schema module
    deriving `Flop.Schema`.
  - Pass the `:backend` option to pick up the default values from your backend
    configuration.
  - If neither the schema module nor the backend module have default options
    set, the function will fall back to the application environment.

  ## Encoding queries

  To encode the returned query as a string, you will need to use
  `Plug.Conn.Query.encode/1`. `URI.encode_query/1` does not support bracket
  notation for arrays and maps.

  ## Date and time filters

  If you use the result of this function directly with
  `Phoenix.VerifiedRoutes.sigil_p/2` for verified routes or in a route helper
  function, all cast filter values need to be able to be converted to a string
  using the `Phoenix.Param` protocol.

  This protocol is implemented by default for integers, binaries, atoms, and
  structs. For structs, Phoenix's default behavior is to fetch the id field.

  If you have filters with `Date`, `DateTime`, `NaiveDateTime`,
  `Time` values, or any other custom structs (e.g. structs that represent
  composite types like a range column), you will need to implement the protocol
  for these specific structs in your application.

      defimpl Phoenix.Param, for: Date do
        def to_param(%Date{} = d), do: to_string(d)
      end

      defimpl Phoenix.Param, for: DateTime do
        def to_param(%DateTime{} = dt), do: to_string(dt)
      end

      defimpl Phoenix.Param, for: NaiveDateTime do
        def to_param(%NaiveDateTime{} = dt), do: to_string(dt)
      end

      defimpl Phoenix.Param, for: Time do
        def to_param(%Time{} = t), do: to_string(t)
      end

  It is important that the chosen string representation can be cast back into
  the Ecto type.

  ## Examples

      iex> to_query(%Flop{})
      []

      iex> f = %Flop{page: 5, page_size: 20}
      iex> to_query(f)
      [page_size: 20, page: 5]

      iex> f = %Flop{first: 20, after: "g3QAAAABZAAEbmFtZW0AAAAFQXBwbGU="}
      iex> to_query(f)
      [first: 20, after: "g3QAAAABZAAEbmFtZW0AAAAFQXBwbGU="]

      iex> f = %Flop{
      ...>   filters: [
      ...>     %Flop.Filter{field: :name, op: :=~, value: "Mag"},
      ...>     %Flop.Filter{field: :age, op: :>, value: 25}
      ...>   ]
      ...> }
      iex> to_query(f)
      [
        filters: %{
          0 => %{field: :name, op: :=~, value: "Mag"},
          1 => %{field: :age, op: :>, value: 25}
        }
      ]
      iex> to_query(f)
      [filters: %{0 => %{value: "Mag", op: :=~, field: :name}, 1 => %{value: 25, op: :>, field: :age}}]

      iex> f = %Flop{page: 5, page_size: 20}
      iex> to_query(f, default_limit: 20)
      [page: 5]

  Encoding the query as a string:

      iex> f = %Flop{order_by: [:name, :age], order_directions: [:desc, :asc]}
      iex> to_query(f)
      [order_directions: [:desc, :asc], order_by: [:name, :age]]
      iex> f |> to_query |> Plug.Conn.Query.encode()
      "order_directions[]=desc&order_directions[]=asc&order_by[]=name&order_by[]=age"
  """
  @doc since: "0.6.0"
  @spec to_query(Flop.t()) :: keyword
  def to_query(%Flop{filters: filters} = flop, opts \\ []) do
    filter_map =
      filters
      |> Stream.with_index()
      |> Enum.into(%{}, fn {filter, index} ->
        {index, Map.from_struct(filter)}
      end)

    default_limit = Flop.get_option(:default_limit, opts)
    default_order = Flop.get_option(:default_order, opts)

    []
    |> Misc.maybe_put(:offset, flop.offset, 0)
    |> Misc.maybe_put(:page, flop.page, 1)
    |> Misc.maybe_put(:after, flop.after)
    |> Misc.maybe_put(:before, flop.before)
    |> Misc.maybe_put(:page_size, flop.page_size, default_limit)
    |> Misc.maybe_put(:limit, flop.limit, default_limit)
    |> Misc.maybe_put(:first, flop.first, default_limit)
    |> Misc.maybe_put(:last, flop.last, default_limit)
    |> Misc.maybe_put_order_params(flop, default_order)
    |> Misc.maybe_put(:filters, filter_map)
  end

  @doc """
  Builds a path that includes query parameters for the given `Flop` struct
  using the referenced Phoenix path helper function.

  The first argument can be either one of:

  - an MFA tuple (module, function name as atom, arguments)
  - a 2-tuple (function, arguments)
  - a URL string, usually produced with a verified route (e.g. `~p"/some/path"`)
  - a function that takes the Flop parameters as a keyword list as an argument

  Default values for `limit`, `page_size`, `order_by` and `order_directions` are
  omitted from the query parameters. To pick up the default parameters from a
  schema module deriving `Flop.Schema`, you need to pass the `:for` option. To
  pick up the default parameters from the backend module, you need to pass the
  `:backend` option. If you pass a `Flop.Meta` struct as the second argument,
  these options are retrieved from the struct automatically.

  > #### Date and Time Filters {: .info}
  >
  > When using filters on `Date`, `DateTime`, `NaiveDateTime` or `Time` fields,
  > you may need to implement the `Phoenix.Param` protocol for these structs.
  > See the documentation for `to_query/2`.

  ## Examples

  ### With a verified route

  The examples below use plain URL strings without the p-sigil, so that the
  doc tests work, but in your application, you can use verified routes or
  anything else that produces a URL.

      iex> flop = %Flop{page: 2, page_size: 10}
      iex> path = build_path("/pets", flop)
      iex> %URI{path: parsed_path, query: parsed_query} = URI.parse(path)
      iex> {parsed_path, URI.decode_query(parsed_query)}
      {"/pets", %{"page" => "2", "page_size" => "10"}}

  The Flop query parameters will be merged into existing query parameters.

      iex> flop = %Flop{page: 2, page_size: 10}
      iex> path = build_path("/pets?species=dogs", flop)
      iex> %URI{path: parsed_path, query: parsed_query} = URI.parse(path)
      iex> {parsed_path, URI.decode_query(parsed_query)}
      {"/pets", %{"page" => "2", "page_size" => "10", "species" => "dogs"}}

  ### With an MFA tuple

      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path(
      ...>   {Flop.PhoenixTest, :route_helper, [%Plug.Conn{}, :pets]},
      ...>   flop
      ...> )
      "/pets?page_size=10&page=2"

  ### With a function/arguments tuple

      iex> pet_path = fn _conn, :index, query ->
      ...>   "/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path({pet_path, [%Plug.Conn{}, :index]}, flop)
      "/pets?page_size=10&page=2"

  We're defining fake path helpers for the scope of the doctests. In a real
  Phoenix application, you would pass something like
  `{Routes, :pet_path, args}` or `{&Routes.pet_path/3, args}` as the
  first argument.

  ### Passing a `Flop.Meta` struct or a keyword list

  You can also pass a `Flop.Meta` struct or a keyword list as the third
  argument.

      iex> pet_path = fn _conn, :index, query ->
      ...>   "/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> meta = %Flop.Meta{flop: flop}
      iex> build_path({pet_path, [%Plug.Conn{}, :index]}, meta)
      "/pets?page_size=10&page=2"
      iex> query_params = to_query(flop)
      iex> build_path({pet_path, [%Plug.Conn{}, :index]}, query_params)
      "/pets?page_size=10&page=2"

  ### Additional path parameters

  If the path helper takes additional path parameters, just add them to the
  second argument.

      iex> user_pet_path = fn _conn, :index, id, query ->
      ...>   "/users/\#{id}/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path({user_pet_path, [%Plug.Conn{}, :index, 123]}, flop)
      "/users/123/pets?page_size=10&page=2"

  ### Additional query parameters

  If the last path helper argument is a query parameter list, the Flop
  parameters are merged into it.

      iex> pet_url = fn _conn, :index, query ->
      ...>   "https://pets.flop/pets?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> flop = %Flop{order_by: :name, order_directions: [:desc]}
      iex> build_path({pet_url, [%Plug.Conn{}, :index, [user_id: 123]]}, flop)
      "https://pets.flop/pets?user_id=123&order_directions[]=desc&order_by=name"
      iex> build_path(
      ...>   {pet_url,
      ...>    [%Plug.Conn{}, :index, [category: "small", user_id: 123]]},
      ...>   flop
      ...> )
      "https://pets.flop/pets?category=small&user_id=123&order_directions[]=desc&order_by=name"

  ### Set page as path parameter

  Finally, you can also pass a function that takes the Flop parameters as
  a keyword list as an argument. Default values will not be included in the
  parameters passed to the function. You can use this if you need to set some
  of the parameters as path parameters instead of query parameters.

      iex> flop = %Flop{page: 2, page_size: 10}
      iex> build_path(
      ...>   fn params ->
      ...>     {page, params} = Keyword.pop(params, :page)
      ...>     query = Plug.Conn.Query.encode(params)
      ...>     if page, do: "/pets/page/\#{page}?\#{query}", else: "/pets?\#{query}"
      ...>   end,
      ...>   flop
      ...> )
      "/pets/page/2?page_size=10"

  Note that in this example, the anonymous function just returns a string. With
  Phoenix 1.7, you will be able to use verified routes.

      build_path(
        fn params ->
          {page, query} = Keyword.pop(params, :page)
          if page, do: ~p"/pets/page/\#{page}?\#{query}", else: ~p"/pets?\#{query}"
        end,
        flop
      )

  Note that the keyword list passed to the path builder function is built using
  `Plug.Conn.Query.encode/2`, which means filters are formatted as map with
  integer keys.

  ### Set filter value as path parameter

  If you need to set a filter value as a path parameter, you can use
  `Flop.Filter.pop/3`.

      iex> flop = %Flop{
      ...>   page: 5,
      ...>   order_by: [:published_at],
      ...>   filters: [
      ...>     %Flop.Filter{field: :category, op: :==, value: "announcements"}
      ...>   ]
      ...> }
      iex> build_path(
      ...>   fn params ->
      ...>     {page, params} = Keyword.pop(params, :page)
      ...>     filters = Keyword.get(params, :filters, [])
      ...>     {category, filters} = Flop.Filter.pop(filters, :category)
      ...>     params = Keyword.put(params, :filters, filters)
      ...>     query = Plug.Conn.Query.encode(params)
      ...>
      ...>     case {page, category} do
      ...>       {nil, nil} -> "/articles?\#{query}"
      ...>       {page, nil} -> "/articles/page/\#{page}?\#{query}"
      ...>       {nil, %{value: category}} -> "/articles/category/\#{category}?\#{query}"
      ...>       {page, %{value: category}} -> "/articles/category/\#{category}/page/\#{page}?\#{query}"
      ...>     end
      ...>   end,
      ...>   flop
      ...> )
      "/articles/category/announcements/page/5?order_by[]=published_at"
  """
  @doc since: "0.6.0"
  @spec build_path(
          String.t()
          | {module, atom, [any]}
          | {function, [any]}
          | (keyword -> String.t()),
          Meta.t() | Flop.t() | keyword,
          keyword
        ) :: String.t()
  def build_path(path, meta_or_flop_or_params, opts \\ [])

  def build_path(
        path,
        %Meta{backend: backend, flop: flop, schema: schema},
        opts
      ) do
    build_path(
      path,
      flop,
      opts |> Keyword.put(:backend, backend) |> Keyword.put(:for, schema)
    )
  end

  def build_path(path, %Flop{} = flop, opts) do
    build_path(path, Flop.Phoenix.to_query(flop, opts))
  end

  def build_path({module, func, args}, flop_params, _opts)
      when is_atom(module) and
             is_atom(func) and
             is_list(args) and
             is_list(flop_params) do
    final_args = build_final_args(args, flop_params)
    apply(module, func, final_args)
  end

  def build_path({func, args}, flop_params, _opts)
      when is_function(func) and
             is_list(args) and
             is_list(flop_params) do
    final_args = build_final_args(args, flop_params)
    apply(func, final_args)
  end

  def build_path(func, flop_params, _opts)
      when is_function(func, 1) and is_list(flop_params) do
    func.(flop_params)
  end

  def build_path(uri, flop_params, _opts)
      when is_binary(uri) and is_list(flop_params) do
    uri = URI.parse(uri)

    query =
      (uri.query || "")
      |> Query.decode()
      |> Map.merge(Map.new(flop_params))

    query = if query != %{}, do: Query.encode(query), else: nil

    uri
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  defp build_final_args(args, flop_params) do
    case Enum.reverse(args) do
      [last_arg | rest] when is_list(last_arg) ->
        query_arg = Keyword.merge(last_arg, flop_params)
        Enum.reverse([query_arg | rest])

      _ ->
        args ++ [flop_params]
    end
  end
end
