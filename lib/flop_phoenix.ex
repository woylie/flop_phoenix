defmodule Flop.Phoenix do
  @moduledoc """
  Phoenix components for pagination, sortable tables and filter forms with
  [Flop](https://hex.pm/packages/flop).

  ## Introduction

  Please refer to the [Readme](README.md) for an introduction.

  ## Customization

  The default classes, attributes, texts and symbols can be overridden by
  passing the `opts` assign. Since you probably will use the same `opts` in all
  your templates, you can globally configure an `opts` provider function for
  each component.

  The functions have to return the options as a keyword list. The overrides
  are deep-merged into the default options.

      defmodule MyAppWeb.CoreComponents do
        use Phoenix.Component

        def pagination_opts do
           [
            ellipsis_attrs: [class: "ellipsis"],
            ellipsis_content: "‥",
            next_link_attrs: [class: "next"],
            next_link_content: next_icon(),
            page_links: {:ellipsis, 7},
            pagination_link_aria_label: &"\#{&1}ページ目へ",
            previous_link_attrs: [class: "prev"],
            previous_link_content: previous_icon()
          ]
        end

        defp next_icon do
          assigns = %{}

          ~H\"""
          <i class="fas fa-chevron-right"/>
          \"""
        end

        defp previous_icon do
          assigns = %{}

          ~H\"""
          <i class="fas fa-chevron-left"/>
          \"""
        end

        def table_opts do
          [
            container: true,
            container_attrs: [class: "table-container"],
            no_results_content: no_results_content(),
            table_attrs: [class: "table"]
          ]
        end

        defp no_results_content do
          assigns = %{}

          ~H\"""
          <p>Nothing found.</p>
          \"""
        end
      end

  Refer to `t:pagination_option/0` and `t:table_option/0` for a list of
  available options and defaults.

  Once you have defined these functions, you can reference them with a
  module/function tuple in `config/config.exs`.

  ```elixir
  config :flop_phoenix,
    pagination: [opts: {MyApp.CoreComponents, :pagination_opts}],
    table: [opts: {MyApp.CoreComponents, :table_opts}]
  ```

  ## Hiding default parameters

  Default values for page size and ordering are omitted from the query
  parameters. If you pass the `:for` assign, the Flop.Phoenix function will
  pick up the default values from the schema module deriving `Flop.Schema`.

  ## Links

  Links are generated with `Phoenix.Components.link/1`. This will
  lead to `<a>` tags with `data-phx-link` and `data-phx-link-state` attributes,
  which will be ignored outside of LiveViews and LiveComponents.

  When used within a LiveView or LiveComponent, you will need to handle the new
  params in the `c:Phoenix.LiveView.handle_params/3` callback of your LiveView
  module.

  ## Using JS commands

  You can pass a `Phoenix.LiveView.JS` command as `on_paginate` and `on_sort`
  attributes.

  If used with the `path` attribute, the URL will be patched _and_ the given
  JS command will be executed.

  If used without the `path` attribute, you will need to include a `push`
  command to trigger an event when a pagination or sort link is clicked.

  You can set a different target by assigning a `:target`. The value
  will be used as the `phx-target` attribute.

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

  You will need to handle the event in the `c:Phoenix.LiveView.handle_event/3`
  or `c:Phoenix.LiveComponent.handle_event/3` callback of your
  LiveView or LiveComponent module. The event name will be the one you set with
  the `:event` option.

      def handle_event("paginate-pets", %{"page" => page}, socket) do
        flop = Flop.set_page(socket.assigns.meta.flop, page)

        with {:ok, {pets, meta}} <- Pets.list_pets(flop) do
          {:noreply, assign(socket, pets: pets, meta: meta)}
        end
      end

      def handle_event("sort-pets", %{"order" => order}, socket) do
        flop = Flop.push_order(socket.assigns.meta.flop, order)

        with {:ok, {pets, meta}} <- Pets.list_pets(flop) do
          {:noreply, assign(socket, pets: pets, meta: meta)}
        end
      end
  """

  use Phoenix.Component

  import Phoenix.HTML.Form,
    only: [
      input_id: 2,
      input_name: 2,
      input_value: 2
    ]

  import PhoenixHTMLHelpers.Form, only: [humanize: 1]

  alias Flop.Meta
  alias Flop.Phoenix.CursorPagination
  alias Flop.Phoenix.Misc
  alias Flop.Phoenix.Pagination
  alias Flop.Phoenix.Table
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS
  alias Plug.Conn.Query

  @typedoc """
  Defines the available options for `Flop.Phoenix.pagination/1`.

  - `:current_link_attrs` - The attributes for the link to the current page.
    Default: `#{inspect(Pagination.default_opts()[:current_link_attrs])}`.
  - `:disabled` - The class which is added to disabled links. Default:
    `#{inspect(Pagination.default_opts()[:disabled_class])}`.
  - `:ellipsis_attrs` - The attributes for the `<span>` that wraps the
    ellipsis.
    Default: `#{inspect(Pagination.default_opts()[:ellipsis_attrs])}`.
  - `:ellipsis_content` - The content for the ellipsis element.
    Default: `#{inspect(Pagination.default_opts()[:ellipsis_content])}`.
  - `:next_link_attrs` - The attributes for the link to the next page.
    Default: `#{inspect(Pagination.default_opts()[:next_link_attrs])}`.
  - `:next_link_content` - The content for the link to the next page.
    Default: `#{inspect(Pagination.default_opts()[:next_link_content])}`.
  - `:page_links` - Specifies how many page links should be rendered.
    Default: `#{inspect(Pagination.default_opts()[:page_links])}`.
    - `:all` - Renders all page links.
    - `{:ellipsis, n}` - Renders `n` page links. Renders ellipsis elements if
      there are more pages than displayed.
    - `:hide` - Does not render any page links.
  - `:pagination_link_aria_label` - 1-arity function that takes a page number
    and returns an aria label for the corresponding page link.
    Default: `&"Go to page \#{&1}"`.
  - `:pagination_link_attrs` - The attributes for the pagination links.
    Default: `#{inspect(Pagination.default_opts()[:pagination_link_attrs])}`.
  - `:pagination_list_attrs` - The attributes for the pagination list.
    Default: `#{inspect(Pagination.default_opts()[:pagination_list_attrs])}`.
  - `:previous_link_attrs` - The attributes for the link to the previous page.
    Default: `#{inspect(Pagination.default_opts()[:previous_link_attrs])}`.
  - `:previous_link_content` - The content for the link to the previous page.
    Default: `#{inspect(Pagination.default_opts()[:previous_link_content])}`.
  - `:wrapper_attrs` - The attributes for the `<nav>` element that wraps the
    pagination links.
    Default: `#{inspect(Pagination.default_opts()[:wrapper_attrs])}`.
  """
  @type pagination_option ::
          {:current_link_attrs, keyword}
          | {:disabled_class, String.t()}
          | {:ellipsis_attrs, keyword}
          | {:ellipsis_content, Phoenix.HTML.safe() | binary}
          | {:next_link_attrs, keyword}
          | {:next_link_content, Phoenix.HTML.safe() | binary}
          | {:page_links, :all | :hide | {:ellipsis, pos_integer}}
          | {:pagination_link_aria_label, (pos_integer -> binary)}
          | {:pagination_link_attrs, keyword}
          | {:pagination_list_attrs, keyword}
          | {:previous_link_attrs, keyword}
          | {:previous_link_content, Phoenix.HTML.safe() | binary}
          | {:wrapper_attrs, keyword}

  @typedoc """
  Defines the available options for `Flop.Phoenix.cursor_pagination/1`.

  - `:disabled` - The class which is added to disabled links. Default:
    `#{inspect(CursorPagination.default_opts()[:disabled_class])}`.
  - `:next_link_attrs` - The attributes for the link to the next page.
    Default: `#{inspect(CursorPagination.default_opts()[:next_link_attrs])}`.
  - `:next_link_content` - The content for the link to the next page.
    Default: `#{inspect(CursorPagination.default_opts()[:next_link_content])}`.
  - `:previous_link_attrs` - The attributes for the link to the previous page.
    Default: `#{inspect(CursorPagination.default_opts()[:previous_link_attrs])}`.
  - `:previous_link_content` - The content for the link to the previous page.
    Default: `#{inspect(CursorPagination.default_opts()[:previous_link_content])}`.
  - `:wrapper_attrs` - The attributes for the `<nav>` element that wraps the
    pagination links.
    Default: `#{inspect(CursorPagination.default_opts()[:wrapper_attrs])}`.
  """
  @type cursor_pagination_option ::
          {:disabled_class, String.t()}
          | {:next_link_attrs, keyword}
          | {:next_link_content, Phoenix.HTML.safe() | binary}
          | {:previous_link_attrs, keyword}
          | {:previous_link_content, Phoenix.HTML.safe() | binary}
          | {:wrapper_attrs, keyword}

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
  - `:th_wrapper_attrs` - The attributes for the `<span>` element that wraps the
    header link and the order direction symbol.
    Default: `#{inspect(Table.default_opts()[:th_wrapper_attrs])}`.
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
          | {:th_wrapper_attrs, keyword}
          | {:thead_th_attrs, keyword}
          | {:thead_tr_attrs, keyword}

  @doc """
  Generates a pagination element.

  ## Examples

      <Flop.Phoenix.pagination
        meta={@meta}
        path={~p"/pets"}
      />

      <Flop.Phoenix.pagination
        meta={@meta}
        path={{Routes, :pet_path, [@socket, :index]}}
      />

  ## Page link options

  By default, page links for all pages are shown. You can limit the number of
  page links or disable them altogether by passing the `:page_links` option.

  - `:all`: Show all page links (default).
  - `:hide`: Don't show any page links. Only the previous/next links will be
    shown.
  - `{:ellipsis, x}`: Limits the number of page links. The first and last page
    are always displayed. The `x` refers to the number of additional page links
    to show.

  ## Pagination link aria label

  For the page links, there is the `:pagination_link_aria_label` option to set
  the aria label. Since the page number is usually part of the aria label, you
  need to pass a function that takes the page number as an integer and returns
  the label as a string. The default is `&"Goto page \#{&1}"`.

  ## Previous/next links

  By default, the previous and next links contain the texts `Previous` and
  `Next`. To change this, you can pass the `:previous_link_content` and
  `:next_link_content` options.
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

        <.pagination
          meta={@meta}
          on_paginate={
            JS.dispatch("my_app:scroll_to", to: "#pet-table") |> JS.push("paginate")
          }
        />

    If used with the `path` attribute, the URL is patched _and_ the given
    JS command is executed.

        <.pagination
          meta={@meta}
          path={~"/pets"}
          on_paginate={JS.dispatch("my_app:scroll_to", to: "#pet-table")}
        />

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

  attr :event, :string,
    default: nil,
    doc: """
    If set, `Flop.Phoenix` will render links with a `phx-click` attribute.
    Alternatively, set `:path`, if you want the parameters to appear in the URL.
    Deprecated in favor of `on_paginate`.
    """

  attr :target, :string,
    default: nil,
    doc: """
    Sets the `phx-target` attribute for the pagination links.
    """

  attr :opts, :list,
    default: [],
    doc: """
    Options to customize the pagination. See
    `t:Flop.Phoenix.pagination_option/0`. Note that the options passed to the
    function are deep merged into the default options. Since these options will
    likely be the same for all the tables in a project, it is recommended to
    define them once in a function or set them in a wrapper function as
    described in the `Customization` section of the module documentation.
    """

  def pagination(%{path: nil, on_paginate: nil, event: nil}) do
    raise Flop.Phoenix.PathOrJSError, component: :pagination
  end

  def pagination(%{meta: meta, opts: opts, path: path} = assigns) do
    assigns =
      assigns
      |> assign(:opts, Pagination.merge_opts(opts))
      |> assign(
        :page_link_helper,
        Pagination.build_page_link_helper(meta, path)
      )
      |> assign(:path, nil)

    ~H"""
    <nav :if={@meta.errors == [] && @meta.total_pages > 1} {@opts[:wrapper_attrs]}>
      <.pagination_link
        disabled={!@meta.has_previous_page?}
        disabled_class={@opts[:disabled_class]}
        event={@event}
        target={@target}
        page={@meta.previous_page}
        path={@page_link_helper.(@meta.previous_page)}
        on_paginate={@on_paginate}
        {@opts[:previous_link_attrs]}
      >
        <%= @opts[:previous_link_content] %>
      </.pagination_link>
      <.pagination_link
        disabled={!@meta.has_next_page?}
        disabled_class={@opts[:disabled_class]}
        event={@event}
        target={@target}
        page={@meta.next_page}
        path={@page_link_helper.(@meta.next_page)}
        on_paginate={@on_paginate}
        {@opts[:next_link_attrs]}
      >
        <%= @opts[:next_link_content] %>
      </.pagination_link>
      <.page_links
        event={@event}
        meta={@meta}
        on_paginate={@on_paginate}
        page_link_helper={@page_link_helper}
        opts={@opts}
        target={@target}
      />
    </nav>
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :on_paginate, JS
  attr :page_link_helper, :any, required: true
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true

  defp page_links(%{meta: meta} = assigns) do
    max_pages =
      Pagination.max_pages(assigns.opts[:page_links], assigns.meta.total_pages)

    range =
      first..last =
      Pagination.get_page_link_range(
        meta.current_page,
        max_pages,
        meta.total_pages
      )

    assigns = assign(assigns, first: first, last: last, range: range)

    ~H"""
    <ul :if={@opts[:page_links] != :hide} {@opts[:pagination_list_attrs]}>
      <li :if={@first > 1}>
        <.pagination_link
          event={@event}
          target={@target}
          page={1}
          path={@page_link_helper.(1)}
          on_paginate={@on_paginate}
          {Pagination.attrs_for_page_link(1, @meta, @opts)}
        >
          1
        </.pagination_link>
      </li>

      <li :if={@first > 2}>
        <span {@opts[:ellipsis_attrs]}><%= @opts[:ellipsis_content] %></span>
      </li>

      <li :for={page <- @range}>
        <.pagination_link
          event={@event}
          target={@target}
          page={page}
          path={@page_link_helper.(page)}
          on_paginate={@on_paginate}
          {Pagination.attrs_for_page_link(page, @meta, @opts)}
        >
          <%= page %>
        </.pagination_link>
      </li>

      <li :if={@last < @meta.total_pages - 1}>
        <span {@opts[:ellipsis_attrs]}><%= @opts[:ellipsis_content] %></span>
      </li>

      <li :if={@last < @meta.total_pages}>
        <.pagination_link
          event={@event}
          target={@target}
          page={@meta.total_pages}
          path={@page_link_helper.(@meta.total_pages)}
          on_paginate={@on_paginate}
          {Pagination.attrs_for_page_link(@meta.total_pages, @meta, @opts)}
        >
          <%= @meta.total_pages %>
        </.pagination_link>
      </li>
    </ul>
    """
  end

  attr :path, :string
  attr :on_paginate, JS
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :page, :integer, required: true
  attr :disabled, :boolean, default: false
  attr :disabled_class, :string
  attr :rest, :global
  slot :inner_block

  defp pagination_link(
         %{disabled: true, disabled_class: disabled_class} = assigns
       ) do
    rest =
      Map.update(assigns.rest, :class, disabled_class, fn class ->
        [class, disabled_class]
      end)

    assigns = assign(assigns, :rest, rest)

    ~H"""
    <span {@rest} class={@disabled_class}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp pagination_link(%{event: event} = assigns) when is_binary(event) do
    ~H"""
    <.link phx-click={@event} phx-target={@target} phx-value-page={@page} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp pagination_link(%{on_paginate: nil, path: path} = assigns)
       when is_binary(path) do
    ~H"""
    <.link patch={@path} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp pagination_link(%{} = assigns) do
    ~H"""
    <.link
      patch={@path}
      phx-click={@on_paginate}
      phx-target={@target}
      phx-value-page={@page}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders a cursor pagination element.

  ## Examples

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={~p"/pets"}
      />

      <Flop.Phoenix.cursor_pagination
        meta={@meta}
        path={{Routes, :pet_path, [@socket, :index]}}
      />

  ## Handling parameters and JS commands

  If you set the `path` assign, a link with query parameters is rendered.
  In a LiveView, you need to handle the parameters in the
  `c:Phoenix.LiveView.handle_params/3` callback.

      def handle_params(params, _, socket) do
        {pets, meta} = MyApp.list_pets(params)
        {:noreply, assign(socket, meta: meta, pets: pets)}
      end

  If you use LiveView and set the `on_paginate` attribute, you need to update
  the Flop parameters in the `handle_event/3` callback.

      def handle_event("paginate-users", %{"to" => to}, socket) do
        flop = Flop.set_cursor(socket.assigns.meta, to)
        {pets, meta} = MyApp.list_pets(flop)
        {:noreply, assign(socket, meta: meta, pets: pets)}
      end

  ## Getting the right parameters from Flop

  This component requires the start and end cursors to be set in `Flop.Meta`. If
  you pass a `Flop.Meta` struct with page or offset-based parameters, this will
  result in an error. You can enforce cursor-based pagination in your query
  function with the `default_pagination_type` and `pagination_types` options.

      def list_pets(params) do
        Flop.validate_and_run!(Pet, params,
          for: Pet,
          default_pagination_type: :first,
          pagination_types: [:first, :last]
        )
      end

  `default_pagination_type` ensures that Flop defaults to the right pagination
  type when it cannot determine the type from the parameters. `pagination_types`
  ensures that parameters for other types are not accepted.

  ## Order fields

  The pagination cursor is based on the `ORDER BY` fields of the query. It is
  important that the combination of order fields is unique across the data set.
  You can use:

  - the field with the primary key
  - a field with a unique index
  - all fields of a composite primary key or unique index

  If you want to order by fields that are not unique, you can add the primary
  key as the last order field. For example, if you want to order by family name
  and given name, you should set the `order_by` parameter to
  `[:family_name, :given_name, :id]`.
  """
  @doc section: :components
  @spec cursor_pagination(map) :: Phoenix.LiveView.Rendered.t()

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
    well, the URL is patched _and_ the given JS command is executed.

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

        <.cursor_pagination
          meta={@meta}
          on_paginate={
            JS.dispatch("my_app:scroll_to", to: "#pet-table") |> JS.push("paginate")
          }
        />

    If used with the `path` attribute, the URL is patched _and_ the given JS
    command is executed.

        <.cursor_pagination
          meta={@meta}
          path={~"/pets"}
          on_paginate={JS.dispatch("my_app:scroll_to", to: "#pet-table")}
        />

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

  attr :event, :string,
    default: nil,
    doc: """
    If set, `Flop.Phoenix` will render links with a `phx-click` attribute.
    Alternatively, set `:path`, if you want the parameters to appear in the URL.
    Deprecated. Use `on_paginate` instead.
    """

  attr :target, :string,
    default: nil,
    doc: "Sets the `phx-target` attribute for the pagination links."

  attr :reverse, :boolean,
    default: false,
    doc: """
    By default, the `next` link moves forward with the `:after` parameter set to
    the end cursor, and the `previous` link moves backward with the `:before`
    parameter set to the start cursor. If `reverse` is set to `true`, the
    destinations of the links are switched.
    """

  attr :opts, :list,
    default: [],
    doc: """
    Options to customize the pagination. See
    `t:Flop.Phoenix.cursor_pagination_option/0`. Note that the options passed to
    the function are deep merged into the default options. Since these options
    will likely be the same for all the cursor pagination links in a project,
    it is recommended to define them once in a function or set them in a
    wrapper function as described in the `Customization` section of the module
    documentation.
    """

  def cursor_pagination(%{path: nil, on_paginate: nil, event: nil}) do
    raise Flop.Phoenix.PathOrJSError, component: :cursor_pagination
  end

  def cursor_pagination(%{opts: opts} = assigns) do
    assigns = assign(assigns, :opts, CursorPagination.merge_opts(opts))

    ~H"""
    <nav :if={@meta.errors == []} {@opts[:wrapper_attrs]}>
      <.cursor_pagination_link
        direction={if @reverse, do: :next, else: :previous}
        meta={@meta}
        path={@path}
        on_paginate={@on_paginate}
        event={@event}
        target={@target}
        disabled={CursorPagination.disable?(@meta, :previous, @reverse)}
        disabled_class={@opts[:disabled_class]}
        {@opts[:previous_link_attrs]}
      >
        <%= @opts[:previous_link_content] %>
      </.cursor_pagination_link>
      <.cursor_pagination_link
        direction={if @reverse, do: :previous, else: :next}
        meta={@meta}
        path={@path}
        on_paginate={@on_paginate}
        event={@event}
        target={@target}
        disabled={CursorPagination.disable?(@meta, :next, @reverse)}
        disabled_class={@opts[:disabled_class]}
        {@opts[:next_link_attrs]}
      >
        <%= @opts[:next_link_content] %>
      </.cursor_pagination_link>
    </nav>
    """
  end

  attr :direction, :atom, required: true
  attr :meta, Flop.Meta, required: true
  attr :path, :any, required: true
  attr :on_paginate, JS
  attr :event, :string, required: true
  attr :target, :string, required: true
  attr :disabled, :boolean, default: false
  attr :disabled_class, :string, required: true
  attr :rest, :global
  slot :inner_block

  defp cursor_pagination_link(
         %{disabled: true, disabled_class: disabled_class} = assigns
       ) do
    rest =
      Map.update(assigns.rest, :class, disabled_class, fn class ->
        [class, disabled_class]
      end)

    assigns = assign(assigns, :rest, rest)

    ~H"""
    <span {@rest} class={@disabled_class}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp cursor_pagination_link(%{event: event} = assigns)
       when is_binary(event) do
    ~H"""
    <.link phx-click={@event} phx-target={@target} phx-value-to={@direction} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp cursor_pagination_link(%{on_paginate: nil} = assigns) do
    ~H"""
    <.link
      patch={CursorPagination.pagination_path(@direction, @path, @meta)}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp cursor_pagination_link(
         %{direction: direction, path: path, meta: meta} = assigns
       ) do
    path = CursorPagination.pagination_path(direction, path, meta)
    assigns = assign(assigns, :path, path)

    ~H"""
    <.link
      patch={@path}
      phx-click={@on_paginate}
      phx-target={@target}
      phx-value-to={@direction}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Generates a table with sortable columns.

  ## Example

  ```elixir
  <Flop.Phoenix.table items={@pets} meta={@meta} path={~p"/pets"}>
    <:col :let={pet} label="Name" field={:name}><%= pet.name %></:col>
    <:col :let={pet} label="Age" field={:age}><%= pet.age %></:col>
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

        <.table
          items={@items}
          meta={@meta}
          on_sort={
            JS.dispatch("my_app:scroll_to", to: "#pet-table") |> JS.push("sort")
          }
        />

    If used with the `path` attribute, the URL is patched _and_ the given
    JS command is executed.

        <.table
          meta={@meta}
          path={~"/pets"}
          on_sort={JS.dispatch("my_app:scroll_to", to: "#pet-table")}
        />
    """

  attr :event, :string,
    default: nil,
    doc: """
    If set, `Flop.Phoenix` will render links with a `phx-click` attribute.
    Alternatively, set `:path`, if you want the parameters to appear in the URL.
    Deprecated in favor of `on_sort`.
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

  attr :row_click, JS,
    default: nil,
    doc: """
    Sets the `phx-click` function attribute for each row `td`. Expects to be a
    function that receives a row item as an argument. This does not add the
    `phx-click` attribute to the `action` slot.

    Example:

    ```elixir
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

    ```elixir
    <:col :let={pet} label="Name" field={:name} col_style="width: 20%;">
      <%= pet.name %>
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

    attr :show, :boolean,
      doc: """
      Boolean value to conditionally show the column. Defaults to `true`
      Deprecated. Use `:if` instead.
      """

    attr :hide, :boolean,
      doc: """
      Boolean value to conditionally hide the column. Defaults to `false`.
      Deprecated. Use `:if` instead.
      """

    attr :col_style, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_style` assign is set as `style` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background` and `border`
      of a column this way.
      """

    attr :thead_th_attrs, :list,
      doc: """
      Additional attributes to pass to the `<th>` element as a static keyword
      list. Note that these attributes will override any conflicting
      `thead_th_attrs` that are set at the table level.
      """

    attr :th_wrapper_attrs, :list,
      doc: """
      Additional attributes for the `<span>` element that wraps the
      header link and the order direction symbol. Note that these attributes
      will override any conflicting `th_wrapper_attrs` that are set at the table
      level.
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


    ```elixir
    <:action :let={user}>
      <.link navigate={~p"/users/\#{user}"}>Show</.link>
    </:action>
    ```
    """ do
    attr :label, :string, doc: "The content for the header column."

    attr :show, :boolean,
      doc: "Boolean value to conditionally show the column. Defaults to `true`."

    attr :hide, :boolean,
      doc:
        "Boolean value to conditionally hide the column. Defaults to `false`."

    attr :col_style, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_style` assign is set as `style` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background` and `border`
      of a column this way.
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
    default: nil,
    doc: """
    You can optionally add a `foot`. The inner block will be rendered inside
    a `tfoot` element.

        <Flop.Phoenix.table>
          <:foot>
            <tr><td>Total: <span class="total"><%= @total %></span></td></tr>
          </:foot>
        </Flop.Phoenix.table>
    """

  def table(%{path: nil, on_sort: nil, event: nil}) do
    raise Flop.Phoenix.PathOrJSError, component: :table
  end

  def table(%{meta: meta, opts: opts} = assigns) do
    assigns =
      assigns
      |> assign(:opts, Table.merge_opts(opts))
      |> assign_new(:id, fn -> table_id(meta.schema) end)

    ~H"""
    <%= if @items == [] do %>
      <%= @opts[:no_results_content] %>
    <% else %>
      <%= if @opts[:container] do %>
        <div id={@id <> "-container"} {@opts[:container_attrs]}>
          <Table.render
            caption={@caption}
            col={@col}
            foot={@foot}
            on_sort={@on_sort}
            event={@event}
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
          on_sort={@on_sort}
          event={@event}
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

  - The `field` is a `Phoenix.HTML.FormField.t` struct.
  - The `type` is the input type as a string, _not_ the name of the
    `Phoenix.HTML.Form` input function (e.g. `"text"`, not `:text_input`). The
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

        <.filter_fields :let={i} form={@form} fields={[:email, :name]}>
          <.input
            field={i.field}
            label={i.label}
            type={i.type}
            {i.rest}
          />
        </.filter_fields>

    The options passed to the inner block are:

    - `field` - A `Phoenix.HTML.FormField` struct.
    - `type` - The input type as a string.
    - `label` - The label text as a string.
    - `rest` - Any additional options passed in the field options.
    """

  def filter_fields(assigns) do
    ensure_meta_form!(assigns.form)
    fields = normalize_filter_fields(assigns[:fields] || [])
    field_opts = match_field_opts(assigns, fields)
    inputs_for_fields = if assigns[:dynamic], do: nil, else: fields

    assigns =
      assigns
      |> assign(:fields, inputs_for_fields)
      |> assign(:field_opts, field_opts)

    ~H"""
    <.hidden_inputs_for_filter form={@form} />
    <%= for {ff, opts} <- inputs_for_filters(@form, @fields, @field_opts) do %>
      <.hidden_inputs_for_filter form={ff} />
      <%= render_slot(@inner_block, %{
        field: ff[:value],
        label: input_label(ff, opts[:label]),
        type: type_for(ff, opts[:type]),
        rest: Keyword.drop(opts, [:label, :op, :type])
      }) %>
    <% end %>
    """
  end

  defp inputs_for_filters(form, fields, field_opts) do
    form.source
    |> form.impl.to_form(form, :filters, fields: fields)
    |> Enum.zip(field_opts)
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

  defp match_field_opts(%{dynamic: true, form: form}, fields) do
    Enum.map(form.data.filters, fn %Flop.Filter{field: field} ->
      fields[field] || []
    end)
  end

  defp match_field_opts(_, fields) do
    Keyword.values(fields)
  end

  defp input_label(_form, text) when is_binary(text), do: text
  defp input_label(form, nil), do: form |> input_value(:field) |> humanize()

  defp type_for(_form, type) when is_binary(type), do: type
  defp type_for(form, nil), do: input_type_as_string(form)

  defp input_type_as_string(form) do
    form
    |> PhoenixHTMLHelpers.Form.input_type(:value)
    |> to_html_input_type()
  end

  # coveralls-ignore-start

  defp to_html_input_type(:checkbox), do: "checkbox"
  defp to_html_input_type(:color_input), do: "color"
  defp to_html_input_type(:date_input), do: "date"
  defp to_html_input_type(:date_select), do: "date"
  defp to_html_input_type(:datetime_local_input), do: "datetime-local"
  defp to_html_input_type(:datetime_select), do: "datetime-local"
  defp to_html_input_type(:email_input), do: "email"
  defp to_html_input_type(:file_input), do: "file"
  defp to_html_input_type(:hidden_input), do: "hidden"
  defp to_html_input_type(:multiple_select), do: "select"
  defp to_html_input_type(:number_input), do: "number"
  defp to_html_input_type(:password_input), do: "password"
  defp to_html_input_type(:radio_button), do: "radio"
  defp to_html_input_type(:range_input), do: "range"
  defp to_html_input_type(:search_input), do: "search"
  defp to_html_input_type(:select), do: "select"
  defp to_html_input_type(:telephone_input), do: "tel"
  defp to_html_input_type(:text_input), do: "text"
  defp to_html_input_type(:textarea), do: "textarea"
  defp to_html_input_type(:time_input), do: "time"
  defp to_html_input_type(:time_select), do: "time"
  defp to_html_input_type(:url_input), do: "url"

  # coveralls-ignore-end

  defp ensure_meta_form!(%Form{data: %Flop{}, source: %Meta{}}), do: :ok
  defp ensure_meta_form!(_), do: raise(Flop.Phoenix.NoMetaFormError)

  @doc """
  Renders hidden inputs for the given form.

  You can use this for convenience if you have a complex form layout that cannot
  be accomplished with `Flop.Phoenix.filter_fields/1`. Put it as a direct child
  of the `form` component to render the hidden inputs for pagination and order
  parameters. Then use `PhoenixHTMLHelpers.Form.inputs_for/3` to render a single
  filter field, and place this component within the anonymous function to render the
  hidden inputs for the filter field and operator.

  Since the filters are represented as an array in the params, make sure to
  add the `offset` option so that the `Flop.Meta` can be properly mapped back to
  your input fields. For every call to `inputs_for` always add the length of all
  previous calls to `inputs_for` as offset.

      <.form :let={f} for={@meta}>
        <.hidden_inputs_for_filter form={@form} />

        <div class="field-group">
          <div class="field">
            <%= PhoenixHTMLHelpers.Form.inputs_for f, :filters, [fields: [:name]], fn ff -> %>
              <.hidden_inputs_for_filter form={ff} />
              <.input label="Name" type="text" field={{ff, :value}} />
            <% end %>
          </div>
          <div class="field">
            <%= PhoenixHTMLHelpers.Form.inputs_for f, :filters, [fields: [{:email, op: :ilike}], offset: 1], fn ff -> %>
              <.hidden_inputs_for_filter form={ff} />
              <.input label="E-mail" type="email" field={{ff, :value}} />
            <% end %>
          </div>
        </div>
      </.form>
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
  @doc section: :miscellaneous
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
  @doc section: :miscellaneous
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
